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
│   │           └── default.conf # reverse proxyの設定(80を転送)
│   └── html
│       └── index.html
└── README.md
```

### 使い方
1. phpstorm (or idea ultimate) を用意する
1. 下記に用意した ipとホスト を /etc/hosts に追記する
1. cloneしたディレクトリをphpstormを開く
1. ./docker-compose.yml の XDEBUG_HOST を自分のPCのIPアドレスに置き換える
1. File > Setting > Languages & Frameworks > PHP > Debug
    - Xdebug > debug port を 10000 で指定する
        - ( 20_xdebug_setting.ini の xdebug.remote_port と同じものを指定する )
1. debugする
    1. git管理されている Edit Configuration の blog1.nginx.com を選択
    1. 虫のアイコンをクリック
    1. ./blog1.nginx.com/var/www/html/index.php に break pointを貼る
    1. http://blog1.nginx.com/ へアクセスし、breakpointで止まっていたら成功

```/etc/hosts
127.0.0.1 blog1.nginx.com
127.0.0.1 blog2.nginx.com
```

### 備考
Edit Configuration情報を自分で作りたい人用メモ

1. File > Setting > Languages & Frameworks > PHP > Debug
     - Xdebug > debug port を xdebug.remote_port に合わせる
1. File > Setting > Languages & Frameworks > PHP > Server
     - Host は /etc/hosts に追記してあり nginxのdefault.confで指定されていることを確認
     - Mapping は docker-compose.yml のvolumesで設定した場所を指定すること
1. Edit Configuration > Add > PHP Remote Server
     - 上記(PHP > Server)で作成したサーバー情報を選択
     - docker-compose.yml の environment > XDEBUG_HOST で指定したものを選択

#### cert 作り方

mkdir -p certs/blog1.nginx.com/certs; docker run -v $PWD/certs/blog1.nginx.com/certs:/certs  -e SSL_DNS=blog1.nginx.com   -e SSL_SUBJECT=blog1.nginx.com   stakater/ssl-certs-generator:1.0
mkdir -p certs/blog2.nginx.com/certs; docker run -v $PWD/certs/blog2.nginx.com/certs:/certs  -e SSL_DNS=blog2.nginx.com   -e SSL_SUBJECT=blog2.nginx.com   stakater/ssl-certs-generator:1.0
