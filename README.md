### 概要
apacheでVirtual Hostをdockerで切り分ける。
このとき、dockerによって過度に複雑化せずに切り分けられることを望む。

- オンプレ + Apache(Virtual Host) 
  - メリット
    - 設定がわかりやすく簡単
      - 複数のサブドメインがディレクトリごとに設定ができる
  - デメリット
    - デバックを行おうとすると大変
      - 環境が切り分けられておらず、サブドメインごとの環境更新が難しい
      - デバック時にide.keyを指定する必要があるが散逸しがち
        - php.ini
        - conf.d/20_xdebug.ini
        - .htaccess
          - `php_value xdebug.remote_host=10.0.0.5`
        - bookmarklet
  - オンプレサーバーだとデバック自体が大変
- vagrant (Virtual Box) + Apache(Virtual Host) 
  - メリット
    - 個人ごとに環境を切り分けた上で検証確認が可能
    - バイナリファイルの配布で可能
    - デバックがしやすい
    - ファイル同期がよりわかりやすく
    - VMが既にあるならかなり簡単に導入が可能
  - デメリット
    - Virtual Host特有の問題が切り分けられていない
    - boxファイル作成手順が失われがち
    - ip addressの管理が面倒

- docker-compose.yml
  - メリット
    - 環境構築手順が実行できる形でドキュメント化されることが保証される
    - サブドメインごとの環境更新が容易
  - デメリット
    -  不用意に扱うとポート番号が増えて管理できなくなる
    
- docker-compose.yml + reverse proxy (nginx)
  - メリット
    - 環境構築手順が実行できる形でドキュメント化されることが保証される
    - サブドメインごとの環境更新が容易
    - ポート番号の管理も容易
  - デメリット
    - リバースプロキシが挟まることによる特有の症状が発生する 
    
#### 備考 reverse proxyとは？
ドメインによりHTTPリクエストを処理するサーバーを変更し、
forwardすることで柔軟にHTTPリクエストを処理・返却する機能。

### 移行手順
#### Virtual Host -> docker-compose.yml + reverse proxy (nginx)

移行元の環境想定
- php 7.0
- Virtual Host
  - blog1.nginx.com
  - blog2.nginx.com
- Xdebug: port = 10000

```
# Ensure that Apache listens on port 80
Listen 80

# Listen for virtual host requests on all IP addresses
NameVirtualHost *:80

<VirtualHost *:80>
DocumentRoot /www/blog1.nginx.com/htdocs
ServerName blog1.nginx.com

# Other directives here

</VirtualHost>

<VirtualHost *:80>
DocumentRoot /www/blog2.nginx.com/htdocs
ServerName blog2.nginx.com

# Other directives here

</VirtualHost>
```

### このリポジトリが完成形
```
.
├── blog1.nginx.com
│   ├── usr
│   │   └── local
│   │       └── etc
│   │           └── php
│   │               └── conf.d
│   │                   └── 20_xdebug_setting.ini 
│   └── var
│       └── www
│           └── html
│               └── index.php
├── blog2.nginx.com
│   ├── usr
│   │   └── local
│   │       └── etc
│   │           └── php
│   │               └── conf.d
│   │                   └── 20_xdebug_setting.ini
│   └── var
│       └── www
│           └── html
│               └── index.php
├── docker-compose.yml # proxy挟んでデバックできるようXDEBUG_HOSTを指定することが肝
├── Dockerfile # php-7.0でデバック可能なapache server
├── proxy
│   ├── etc
│   │   └── nginx
│   │       └── conf.d
│   │           └── default.conf # reverse proxyの設定
│   └── html
│       └── index.html
└── README.md
```

