# AWS Multi-AZ Infrastructure Portfolio

## 概要
2VPC（dev/prod）でのMulti-AZ・3層アーキテクチャを実装し、
高可用性・セキュリティ・スケーラビリティを備えた構成をTerraformでIaC化したポートフォリオです。

## アーキテクチャの特長
- **環境分離**: dev/prod完全分離（VPC: 10.0.x.x / 10.1.x.x）
- **高可用性**: Multi-AZ配置（ap-northeast-1a/1c）
- **3層構成**: Public層（ALB）/ Private App層（EC2）/ Private DB層（RDS）
- **自動スケーリング**: CPU使用率50%基準での1-4台動的制御
- **セキュリティ**: IMDSv2準拠, 最小権限SecurityGroup, SSM接続
- **監視**: CloudWatch Logs統合

## 技術スタック
- **IaC**: Terraform v1.6+, AWS Provider v5.0+
- **インフラ**: VPC, ALB, AutoScaling, EC2, RDS Multi-AZ
- **セキュリティ**: IMDSv2準拠, SecurityGroup参照による動的制御
- **運用**: SSM Session Manager, CloudWatch Logs

## デプロイ手順
1. `terraform.tfvars.example` を `terraform.tfvars` にコピー
2. データベースパスワード等の機密情報を設定
3. 対象環境ディレクトリへ移動
   - 開発環境: `cd environments/dev`
   - 本番環境: `cd environments/prod`
4. Terraform 初期化: `terraform init`
5. 実行計画の確認: `terraform plan`
6. 実行: `terraform apply`

## セキュリティ設計
> **Note**: 機密情報（DBパスワード等）は `.gitignore` によりリポジトリには含めていません。
> `terraform.tfvars.example` を参考に、各自ローカル環境で設定してください。
> 実務環境では AWS Secrets Manager 等との連携を推奨します。

## ディレクトリ構成

portfolio-infra/
├── README.md
├── .gitignore
├── environments/
│   ├── dev/                          # 開発環境（10.0.x.x）
│   │   ├── main.tf                   # モジュール統合・プロバイダー設定
│   │   ├── variables.tf              # 変数定義
│   │   ├── outputs.tf                # 出力値定義
│   │   ├── terraform.tfvars          # 実際の値（.gitignoreで除外）
│   │   └── terraform.tfvars.example  # 公開用サンプル
│   └── prod/                         # 本番環境（10.1.x.x）
│       ├── main.tf                   # モジュール統合・プロバイダー設定
│       ├── variables.tf              # 変数定義
│       ├── outputs.tf                # 出力値定義
│       ├── terraform.tfvars          # 実際の値（.gitignoreで除外）
│       └── terraform.tfvars.example  # 公開用サンプル
└── modules/
    ├── network/                      # VPC, Subnet, Routing
    │   ├── main.tf                   # VPC、サブネット、ルーティング
    │   ├── variables.tf              # ネットワーク用変数
    │   └── outputs.tf                # VPC ID、サブネット ID等
    ├── security/                     # SecurityGroup
    │   ├── main.tf                   # ALB、EC2、RDS用SecurityGroup
    │   ├── variables.tf              # セキュリティ用変数
    │   └── outputs.tf                # SecurityGroup ID
    ├── compute/                      # ALB, ASG, EC2
    │   ├── main.tf                   # ALB、AutoScaling、Launch Template
    │   ├── variables.tf              # コンピュート用変数
    │   └── outputs.tf                # ALB DNS名等
    ├── database/                     # RDS Multi-AZ
    │   ├── main.tf                   # RDS、DBサブネットグループ
    │   ├── variables.tf              # データベース用変数
    │   └── outputs.tf                # RDSエンドポイント
    └── iam/                          # IAMRole, InstanceProfile
        ├── main.tf                   # EC2用IAMロール、インスタンスプロファイル
        ├── variables.tf              # IAM用変数
        └── outputs.tf                # インスタンスプロファイル名

## 設計判断とトレードオフ
### コスト最適化
- NAT Gatewayを各VPCに1台配置（AZ冗長化よりコスト優先）
- 完全冗長化が必要な場合は各AZに配置可能な設計

### セキュリティ強化
- IMDSv2対応によるSSRF攻撃対策
- SecurityGroup参照による動的アクセス制御
- RDS完全プライベート配置

### 運用効率
- モジュール化による環境複製の瞬時実現
- Instance Refreshによる無停止更新
- SSM Session Managerによるセキュアアクセス

## 実装された機能
- **Multi-AZ高可用性**: EC2とRDSの異なるAZ配置
- **自動スケーリング**: CPU使用率50%を基準とした動的スケール（1-4台）
- **ロードバランシング**: ALBによる複数インスタンス間の負荷分散
- **セキュアアクセス**: SSM Session Managerによるセキュアな運用アクセス
- **監視基盤**: CloudWatch Logsとの統合による包括的監視
- **最新セキュリティ**: IMDSv2準拠による最新のセキュリティ仕様対応
