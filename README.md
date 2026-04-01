# AWS Multi-AZ Infrastructure Portfolio

## 概要
AWSの基本的なインフラストラクチャをTerraformでIaC化したポートフォリオです。

## アーキテクチャの特長
- **環境分離**: 2VPC構成でdev/prodを分離（VPC: 10.0.x.x / 10.1.x.x）
- **高可用性**: Multi-AZ配置（ap-northeast-1a/1c）
- **3層構成**: Public層（ALB）/ Private App層（EC2）/ Private DB層（RDS）
- **自動スケーリング**: CPU使用率50%基準での1-4台動的制御
- **包括的監査基盤**: ネットワーク・ロードバランサー・アプリケーション・データベース層でのログ統合

## 技術スタック
- **IaC**: Terraform v1.6+, AWS Provider v5.0+
- **インフラ**: VPC, ALB, AutoScaling, EC2(t3.micro), RDS MySQL Multi-AZ, S3
- **セキュリティ**: SecurityGroup参照による動的制御, SSM Session Manager
- **監視・監査**: VPC Flow Logs, CloudWatch Agent, CloudWatch Logs, ALBアクセスログ(S3)

## 包括的監査・ログ基盤
「監査やログ追跡ができる構成」として、システム全層でのトレーサビリティを実現しています。
ログの性質と用途に応じて、CloudWatch LogsとS3を適材適所で使い分ける設計です。

### CloudWatch Logs（運用監視・30日保持・即時検索）

| ログ種別 | ロググループ | 取得内容 | 用途 |
|---------|------------|---------|------|
| **VPC Flow Logs** | `/aws/vpc/{project}-{env}-flow-logs` | VPC内部の全ネットワーク通信（ALB↔EC2、EC2↔RDS） | 不正アクセス検知・SG動作確認・通信パターン分析 |
| **Apacheアクセスログ** | `/aws/ec2/{project}-{env}/apache/access` | EC2に到達したリクエスト詳細・Instance ID別 | アプリケーション層の負荷分散状況確認 |
| **RDS エラーログ** | `/aws/rds/instance/{identifier}/error` | DB接続エラー・構文エラー | データベース障害の迅速な原因特定 |
| **RDS 一般ログ** | `/aws/rds/instance/{identifier}/general` | 全SQL文の実行履歴（SELECT/INSERT/UPDATE/DELETE） | データベース操作の完全追跡 |
| **RDS スロークエリ** | `/aws/rds/instance/{identifier}/slowquery` | パフォーマンス問題のあるクエリ | DB最適化・ボトルネック特定 |

### Amazon S3（長期監査・分析基盤）

| ログ種別 | 保管先 | 取得内容 | 用途 |
|---------|-------|---------|------|
| **ALBアクセスログ** | `{project}-{env}-alb-logs-{account_id}/alb/` | クライアントIP・リクエストパス・ステータスコード・レイテンシ | 長期監査・Athena分析・外部アクセス追跡 |

> **設計根拠**: ALBアクセスログはAWSの仕様上S3への直接出力のみサポートされているため、
> 実務標準に従いS3へ出力し、その他のログは運用監視を主目的としてCloudWatch Logsに統合しています。

## セキュリティ設計

### SecurityGroup（最小権限の原則・3層分離）

    portfolio-{env}-sg-alb
    ├── Ingress: 0.0.0.0/0 → HTTP:80（インターネットからの接続許可）
    └── Egress: All traffic（ターゲットへの転送用）

    portfolio-{env}-sg-app  
    ├── Ingress: sg-alb → HTTP:80（ALBからのみ接続許可）
    └── Egress: All traffic（SSM接続・パッケージ更新・RDS接続用）

    portfolio-{env}-sg-db
    ├── Ingress: sg-app → MySQL:3306（EC2からのみ接続許可）
    └── Egress: All traffic（レプリケーション用）

### IMDSv2対応（SSRF攻撃対策）
EC2メタデータ取得にトークンベース認証を実装し、Amazon Linux 2023のデフォルトセキュリティ仕様に準拠しています。
従来のIMDSv1では認証なしにメタデータへアクセスできましたが、本構成では以下の2段階認証を実装：

1. トークン取得：`PUT /latest/api/token` でセッショントークンを発行
2. 認証済みアクセス：取得したトークンをヘッダに付与してメタデータ取得

この仕組みによりSSRF攻撃のリスクを大幅に軽減し、セキュリティを強化しています。

### SSM Session Manager
SSH鍵不要のセキュアなEC2アクセスを実現。`AmazonSSMManagedInstanceCore`ポリシーによりブラウザベース接続が可能です。
OSレベルのアクセスはSSMに限定し、SSHポートは開放しない方針で鍵管理の複雑さとリスクを回避しています。

## 設計判断とトレードオフ

### NAT Gateway配置（コスト効率優先）
- **現在の構成**: 各VPCにつき1台
- **設計思想**: アプリケーション層（ALB + ASG）とデータベース層（RDS Multi-AZ）で可用性を担保し、ネットワーク層はコスト効率を優先
- **影響範囲**: AZ-a障害時、EC2のアウトバウンド通信（パッケージ更新等）が一時停止
- **完全冗長化**: 各AZにNAT Gatewayを配置することで対応可能な設計

### RDS Multi-AZ構成
- **高可用性**: Multi-AZ実装済み（同期レプリケーション・自動フェイルオーバー）
- **Read Replica**: 未実装（ポートフォリオ規模では負荷分散よりも障害対策を優先）
- **拡張方針**: 負荷増加時はクエリ最適化を優先し、必要に応じてTerraformでRead Replicaを追加

### ログ管理戦略
- **CloudWatch Logs（30日）**: リアルタイム検索・アラート連携・運用監視
- **S3（長期保管）**: 監査証跡・Athena分析・コンプライアンス対応
- **実務拡張**: S3ライフサイクルポリシーによるGlacier移行で超長期・低コスト保管が可能

### バックアップ設計
- **RDS自動バックアップ**: 7日間保持（Point-in-Time Recovery対応）
- **設計根拠**: Multi-AZで物理障害対策は完了済み。バックアップの役割は論理障害（誤操作等）からの復旧に特化。7日間で実務要件を十分満たしコスト効率を維持

## デプロイ手順

    1. 設定ファイルの準備
       cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
       (terraform.tfvarsにDBパスワード等の実際の値を設定)

    2. 初期化と構築
       cd environments/dev
       terraform init
       terraform plan    # Plan: 42 to add の確認
       terraform apply

    3. 動作確認
       OutputsのALB DNS名にブラウザでアクセス
       CloudWatchコンソールでログ出力を確認

    4. 削除
       terraform destroy

## ディレクトリ構成

    portfolio-infra/
    ├── README.md
    ├── .gitignore
    ├── environments/
    │   ├── dev/                          # 開発環境（10.0.x.x）
    │   │   ├── main.tf                   # モジュール統合・プロバイダー設定
    │   │   ├── variables.tf              # 変数宣言
    │   │   ├── outputs.tf                # ALB DNS名・VPC ID出力
    │   │   ├── terraform.tfvars          # 実際の値（.gitignoreで除外）
    │   │   └── terraform.tfvars.example  # 公開用サンプル
    │   └── prod/                         # 本番環境（10.1.x.x）
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       ├── terraform.tfvars          # 実際の値（.gitignoreで除外）
    │       └── terraform.tfvars.example  # 公開用サンプル
    └── modules/
        ├── network/                      # VPC・サブネット・ルーティング・VPC Flow Logs
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── security/                     # SecurityGroup（ALB/EC2/RDS）
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── compute/                      # ALB・AutoScaling・EC2・S3(ALBログ)
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        ├── database/                     # RDS Multi-AZ・CloudWatch Logsエクスポート
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        └── iam/                          # IAMロール・インスタンスプロファイル
            ├── main.tf
            ├── variables.tf
            └── outputs.tf

## セキュリティに関する注意事項
機密情報（DBパスワード等）は`.gitignore`によりリポジトリには含まれていません。
`terraform.tfvars.example`を参考に、各自ローカル環境で設定してください。
実務環境ではAWS Secrets Manager等との連携を推奨します。

## このポートフォリオ作成において意識していること
- **Multi-AZ・3層アーキテクチャ**: 高可用性を考慮した実務レベルの設計
- **包括的監査基盤**: 4層すべてでのログ統合による完全なトレーサビリティ
- **IaC実装力**: Terraformモジュール化による再利用可能なインフラコード
- **セキュリティ意識**: 最小権限の原則・最新セキュリティ仕様（IMDSv2）への準拠
- **コスト意識**: 要件に応じた適切なトレードオフ判断
- **AWSサービス理解**: 各サービスの特性に応じた適材適所の技術選択
