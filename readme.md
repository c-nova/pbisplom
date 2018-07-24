# R における Power BI カスタムビジュアルの作成方法

[前回](https://github.com/c-nova/pbipltly)は R + Plotly の組み合わせによるカスタム ビジュアルを作成しました。これは Plotly が「R スクリプト ビジュアル」で直接コードして可視化することができないため、カスタム ビジュアルのパッケージとして作成する必要がありました。
しかし R の場合はどうでしょうか？ R の場合は「R スクリプト ビジュアル」が利用できるので、通常パッケージ化は必要ありません。ですが、これはあくまで R 言語を記述できる方が利用する場合の話であり、コーディングができない方では利用できないことに変わりはありません。また、Power BI Desktop では R スクリプトが利用できますが、現在Power BI Service では「R スクリプト ビジュアル」を利用することができません。
そこで R スクリプトのパッケージ化が必要になります。パッケージ化を行うと、以下のような利点があります。

- 毎回 R スクリプトを記述する必要がない
- パッケージ化されているので、組織内で統一されたコードでビジュアルが利用できる
- 細かいパラメータの設定も GUI で設定可能

今回の R でのカスタム ビジュアルは、上記の利点をフルに生かせるようなパッケージの作成方法を説明いたします。

[前回](https://github.com/c-nova/pbipltly)と同じですが、Rについての日本語での解説は [こちら](http://www.okadajp.org/RWiki/?R%E3%81%A8%E3%81%AF) のページをご覧ください。

---

## 1. Power BI における R の制限事項

[このページ](https://docs.microsoft.com/ja-jp/power-bi/desktop-r-visuals#known-limitations) に詳細が記載されていますが、Power BI Desktop で R を利用する場合には以下のような制限事項があります。Desktop 版と Service 版で若干制限事項が異なるので、両方ご利用される場合には厳しい制限に合わせる必要があります。Service 版の制限事項は[こちら](https://docs.microsoft.com/ja-jp/power-bi/service-r-visuals#known-limitations)に記載されております。

### Power BI Desktop、Serivce 共通

- R ビジュアルは他のビジュアル同様、データ更新、フィルター処理、および強調表示の際に反映されます。これは毎回 R スクリプトが処理されることを意味します。
- R ビジュアルは対話的にクロス フィルター処理のソースになることはできません。これは Plotly を利用しても同様で、フィルタ処理のソースは Power BI ネイティブなスライダーなどをご利用ください。同様に R のビジュアル要素をクリックして選択することはできません（これは Plotly を利用する場合を除きます。ホバー ヒントなどを利用してポイントの数値を取得したい場合には、Plotly の採用を検討してください）
- R ビジュアルでプロット可能なデータ量は 150,000 行までとなります。150,000 行を超えた分は表示されず、プロット イメージ上に警告が表示されます
- コンソールと対話的な動きをするパッケージや、コンソールへの動作に介入する（例えば「progress」パッケージを使うなど）パッケージは動作できません
- 日本語のカラム名は R では正常の動作しないことが多いので、英語のカラム名にすることをお勧めします。ただしどうしても日本語で表示を行いたいときには、以下の方法をお試しください

1. R スクリプト内で library を定義する箇所に以下のパッケージを読み込む行を追加する

Desktop の場合 `install.packages("showtext")`
Service の場合 `library("showtext")`

2. 続けて Power BI で `showtext` が利用できるように以下の行を実コード部分の先頭に配置する

`powerbi_rEnableShowTextForCJKLanguages =  1`

### Power BI Desktop での制限事項

- R での計算時間は 5 分までとなります。 5 分を超えるとエラーとなり、プロットできません
- R の既定のディスプレイ デバイスにプロットされるプロットだけが正しく表示されます。 異なる R ディスプレイ デバイスを明示的に使用することは避けてください。これは分かりにくいと思いますが、例えば「rggobi」のような、gtk+ を利用してインタラクティブにデータ探索を行えるモジュールがあります。これは gtk+ を利用して別ディスプレイ デバイスにデータを渡して処理を行います。このようなパッケージを Power BI 上で利用することはできません
- 32bit 版 Power BI では R のインストール パスを手動で入力する必要があります（2018年7月現在）

### Power BI Serviceでの制限事項

- 利用できるパッケージは「CRAN」のような公式リポジトリに登録されている必要があります。最新の対応 R パッケージは[こちら](https://docs.microsoft.com/ja-jp/power-bi/service-r-packages-support)から確認することが可能です。
- Power BI Service では R の計算時間は 60 秒までに制限されます。 60 秒を超えるとエラーとなり、プロットできません
- time データ型はサポートされません。Date/Time型をご利用ください
- 「Web に公開」を使用するとき、R ビジュアルは表示されません
- 2018年7月現在、R ビジュアルはダッシュボードとレポートの印刷機能では印刷されません
- 2018年7月現在、R ビジュアルは Analysis Services の DirectQuery モードでサポートされていません

---

## 2. 作業の流れ

作業の流れは前回とほとんど変わりません。ここでは環境ができている前提として以下の流れで進めていきます。

1. pbibiz new でのプロジェクトの作成
2. R によるコードの記述
3. pbiviz start によるビジュアル サーバーの起動
4. Power BI Service でのテスト実施
5. pbiviz package によるパッケージに作成
6. パッケージのインストール

---

## 3. カスタム ビジュアル プロジェクトの作成

前回は RHTML テンプレートでの「カスタム ビジュアル プロジェクト」を作成しましたが、今回は R ビジュアルのテンプレートを利用します。

`pbiviz new <プロジェクト名> -t rvisual`

---

1. コマンド プロンプトを起動し、プロジェクトを作成するディレクトリ（プロジェクト用ディレクトリは自動作成されるので作成は不要です）に移動します。

---

2. 以下の Node.js コマンドを実行します。今回はデフォルトの Power BI には無い「SPLOM」という複数の散布図（Scatter Plot）の集合体を作成します。ここでは名前は「pbisplom」とします。

`pbiviz new pbisplom -t rvisual`

実行が完了すると以下のように表示されます。

```
 info   Creating new visual
 info   Installing packages...
 info   Installed packages.
 done   Visual creation complete
  ```

---

3. 新しく作成されたディレクトリ（ここでは pbisplom ）に移動します。

`cd pbisplom`

---

4. Visual Server を起動します。

`pbiviz start`

起動が成功すると以下のようなメッセージが表示され、待機状態になります。

```
 info   Building visual...
 done   build complete

 info   Starting server...
 info   Server listening on port 8080.
```

これで Power BI Service からカスタム ビジュアルを使用できるようになりました。
作成後のファイル構成は以下のようになっているはずです。

```cmd:dir
.api
.npmignore
.vscode
assets
capabilities.json
dependencies.json
node_modules
package-lock.json
package.json
pbiviz.json
script.r
src
style
tsconfig.json
tslint.json
```

今回は `script.r` を編集していきます。

---

5. Power BI Service で適当なデータからレポートを作成します。サンプルからデータを取得しても構いませんし、作成済みのデータがあればそれを使用しても構いません。 

---

6. 空のレポートに対して下図にある「開発者向けビジュアル」をクリックします。

<img src="img/PBIS21.png" width=160>

---

7. Plotly の場合とは異なり、データは組み込まれていないので、適当なデータをビジュアルに投入します。

<img src="img/PBIP21.png" width=480>

これで初期動作の確認は完了です。

---

## 4. 基本的なプロット

ここから R のグラフを開発します。
前回は VCS を使用して開発を行いましたが、最初の R のコーディング部分は R Studio を使用して開発を行います。R Studioは[こちら](https://www.rstudio.com/products/rstudio/download/#download)からダウンロードし、インストールしてください。

---

1. R Studio で 先ほど作成したプロジェクト内の script.r を開きます。以下のように表示されるはずです。

```
plot(Values);
```

R のみの場合は非常に単純です。前回同様データは「Values」という変数に代入されていることがわかります。
plot は R のデフォルトのプロット命令です。実はこれでも SPLOM という形式の表示ができるのですが、あくまで散布図だけの対応なので、もっと色々なグラフが表示できるパッケージに変えていきましょう。

---

2. ここでは「[GGally](https://ggobi.github.io/ggally/)」という SPLOM のパッケージを使用します。GGally は [The GGobi Foundation, Inc](http://ggobi.org/foundation/) という団体が作成している ggplot2 の拡張機能です。もともと [GGobi](http://ggobi.org/) 自体も高次元のデータの可視化や探索を得意とするソフトウェアであり、R で利用可能なパッケージ（rggoib）もあるのですが、こちらは GGobi と R を接続するためのパッケージでしかなく、今回の Power BI で使用方法の場合には利用することができません（別の画面が開いて実行される形式となり、Power BI ではサポートされません）。

<img src="img/PBIP22.png" width=480>
GGobiを使ったデータ可視化例

以下に GGally を利用するためのコードを記載します。

```
################# DEBUG in RStudio #################
setwd("C:/<WorkDir>")
Values <- read.csv("<CSV Data File>", sep = ",")
fileRda = "C:/Users/<UserName>/AppData/Local/Temp/tempData.Rda"
if(file.exists(dirname(fileRda)))
{
 if(Sys.getenv("RSTUDIO")!="")
   load(file= fileRda)
 else
   save(list = ls(all.names = TRUE), file=fileRda)
}
####################################################

############### Library Declarations ###############
library("showtext")
#library("progress") <- This moduele not compatible PBI Service
library("scales")
library("colorspace")
library("GGally")
####################################################

################### Actual code ####################
powerbi_rEnableShowTextForCJKLanguages =  1
ggp = ggpairs(Values)
print(ggp, progress = F)
####################################################
```

今回は DEBUG in RStudio の部分を利用します。本来は「fileRda」の部分以降がドキュメントで記載されている部分となりますが、一部使いにくい部分があるので2行ほど追加しています。1行目の `setwd` は作業ディレクトリの場所指定です。ここではコード、ファイルがある場所をしていします。2行目の `Values` は Power BI で読み込まれた際に指定される変数です。R Studio では事前に指定してデータを読み込む必要があります。
3行目の `fileRDA` はそのディレクトリにあるファイル一覧をバイナリ形式で保存するもののようです。こちらは内部的に使用されるようですが、最初に R Studio で実行するとエラーが発生（この Rda ファイルを置くディレクトリが存在しないため）してしまうので、事前にディレクトリまでは作成しておきます。

次に2個目の段落である Library Declarations を見てみましょう。一行目の `showtext` は Power BI で日本語カラムを使用する際に必要なライブラリです。2行目から5行目までが必要なライブラリですが、`progress` というライブラリは注意が必要です。これは重い処理を行う際にコンソール側に `=` 記号で進捗状況を表示するライブラリです。Power BI ではコンソール側で出力をや処理を行うパッケージはサポートされない（読み込もうとすると存在しないというエラーが発生する）ので、ここではコメントしておきます。

そして最後の段落 Actual code です。こちらも一行目は CJK 言語（C:中国語、J:日本語、K:韓国語）で書かれたカラム名の処理についての記述です。
2行目と3行目で一つのセットになって GGally の出力を形成していることに注意してください。2行目のみでも記述は可能なのですが、実は2行目だけで実行した場合、重い処理（15プロット以上 = 4x4の変数によるプロット以上の場合）を実行する際に先ほどの `progress` モジュールが要求されます。それを無効化しているのが3行目の `progress = F` の部分となります。

---

3. 上記のコードを R Studio で実行してみましょう。プロットの画面に以下ようなグラフが表示されます。

<img src="img/PBIP23.png" width=480>

---

4. 上記のように、プロットはモノクロで表示されます。これでは味気ありませんので、特定のカラムのデータを利用して色付けしてみましょう。下記のコード例を利用して色で区分します。区分用のカラムは連続値データではなく、離散値データを利用しましょう

`ggp = ggpairs(Values, mapping = aes(colour = Values[,10]))`

上記では例として Values というデータの10個目のカラムを色付け用データとして利用しています。このデータは三段階の離散値を使用していますので、以下のような色付けになります。

<img src="img/PBIP24.png" width=480>

これで3色に色付けされることがわかりました。色分けをするにはカラム名を指定する必要があり、コードに事前定義するのが難しいので、ここでは一旦元のコードに戻します。

---

5. コードを元に戻し、DEBUG in RStudio の部分をコメント化します。完了後保存し、以下のコマンドをコマンド プロンプトで実行します。

`pbiviz start`

---

6. 再び Power BI Service の画面にもどり、グラフを確認します。先ほど開発者向けビジュアルにデータを投入済みの方は画面の更新が完了するとともに GGally による SPLOM が表示されているはずです。まだデータを投入されていない方は、レポート上のビジュアルを選択後、表示したいデータ選択してください。例として以下のように SPLOM が表示されるはずです。

<img src="img/PBIP25.png" width=480>


```
 info   RScript change detected. Rebuilding...
 done   RScript build complete
 ```

 R + Plotly の際と同様、 `pbiviz` サーバーが自動的に変更を検知してビルドし、サーバーが再起動します。ここで一番左のアイコンをクリックすると手動でリロードが可能ですが、細かく修正を行う場合には左から2番目の矢印付きのアイコンをクリックすると自動リロードモードになりますので、開発フェーズに合わせて設定を行ってください。

<img src="img/PBIP26.png" width=120>

---

## 5. VSCの導入、準備
ここから先は R 以外のコードも実施する必要があるため、R Studio は一旦ここで終了し、Visual Studio Code（以下VSC）を使用してコーディングを行っていきます。早速環境を整えましょう。

1. [前回](https://github.com/c-nova/pbipltly)同様、VCSを起動します。お持ちでなければ[ここ](https://code.visualstudio.com/)からダウンロードして、インストールしてください。
2. 今回はちゃんと？ R のコードを書く必要があるため VSC に R のプラグインを導入します。画面左端上部の最下部にある四角いアイコンをクリックするか、「Ctrl+Shift+X」を押下します。
3. 「拡張機能」ウィンドウが表示されるので、最上部の検索ウィンドウで「R」と入力し、Enterを押下します。
4. R とだけ書かれたパッケージが見つかると思いますので、クリックして拡張機能パッケージの画面を開きます。

<img src="img/VSC21.png" width=480>

5. 上手のようなパッケージであることを確認し、インストールをクリックします。画面上部にある「拡張機能の識別子」が「ikuyadeu.r」であることも念のため確認しておきましょう。
6. インストールが完了したら「再読み込み」ボタンをクリックして再起動します。
7. 「Usage」にも書いてあるように「R のパス」を指定します。「ファイル」->「基本設定」->「設定」の順に開くか、「Ctrl+,」を押下します。
8. 設定画面が開くので、右側にある「ユーザー設定」の JSON 文字列に以下のように追記します。私の環境は Microsoft の Open R 3.5.0 を使用しておりますので以下のようになりますが、皆さんは自身の環境に合わせた内容で記述してください。

`"r.rterm.windows": "C:\\Program Files\\Microsoft\\R Open\\R-3.5.0\\bin\\x64\\R.exe"`

1行上の最後部に「,」を付与することを忘れないようにしましょう。
追記後、以下のような記述になります。

<img src="img/VSC22.png" width=480>

9. 設定を有効化するためにVSCを再起動します。
10. 再起動後、「ファイル」->「フォルダを開く」を開くか、「Ctrl+K -> Ctrl+O」を押下して先ほど作成したプロジェクト フォルダを開きます。
11. 左側のペインに「エクスプローラー」が表示されるので、先ほど作成した「script.r」ファイルをクリックします。
12. 画面上部にある下矢印付きアイコンをクリックするか、「Ctrl+Shift+S」を押下します。この操作により script.r 内のコードが全て実行されます。実行後、以下のような画面が別ウィンドウで表示されます。コンソールしか開かなかった場合には、もう一度同じ操作を実行します。

<img src="img/VSC23.png" width=240>
<img src="img/VSC24.png" width=480>

これでVSCの準備は完了です。

---

## 6. Power BI の機能を利用して色をつける
以前の章では R Studio では色のついたグラフが表示することができました。しかし R Studio での開発とは異なり、Power BI 上では定数を使ったカラムの指定を行うと毎回コードを変更する必要があり、非常に不便です。そこでこの章では Power BI の機能を利用して、ユーザーが自由にデータを投入して色を付けられるようにします。  

1. データを投入する項目を管理しているのは「capability.json」というファイルになります。このファイルは初期状態では以下のようになっています。この内容を見てみましょう。

```
{
  "dataRoles": [
    {
      "displayName": "Values",
      "kind": "GroupingOrMeasure",
      "name": "Values"
    }
  ],
  "dataViewMappings": [
    {
      "scriptResult": {
        "dataInput": {
          "table": {
            "rows": {
              "select": [
                {
                  "for": {
                    "in": "Values"
                  }
                }
              ],
              "dataReductionAlgorithm": {
                "top": {}
              }
            }
          }
        },
～～ 中略 ～～
}
```

入力データ項目を作成する上で注意が必要なのは、上記の「dataRoles」と「dataViewMappings」です。これはそれぞれ以下のような役割があります。

|  | dataRoles | dataViewMappings |
|:-|:---------:|:----------------:|
|役割| 入力項目の名称や受け入れる値に制約を加える|入力項目数を制限したり、dataRoles で入力された値の処理方法を決定する
|主な設定項目|表示名、ヒント文、受け入れデータ形式、内部名称|受け入れ最大/最小項目数、明細またはグループ化データの取り扱い方法|

ここではどのようにデータを受け入れているかを確認できます。まず目につくのは「dataRoles」内の「Values」の項目です。これは Power BI 上で R を使用する際にデフォルトで用意されているデータ投入項目です。「Kind」の部分を見ると「GroupingOrMeasure」となっているので、グループ化用の値も、明細の値もどちらも受け入れ可能になっています。

続いて「dataViewMappings」も見てみましょう。ここでも「Values」という値に注目しましょう。この項目は「scriptingResult」「dataInput」の下の「table」に格納されています。これは「table」というデータ処理機能を使用して「rows」に格納されることを意味します。簡単に言うとテーブル形式で行に格納されることになります。また「"for": { "in": 」を使用しているということで、集計、グループ化されず、そのままのデータを各行に入れるということになります。

まとめると、デフォルトで用意されている「Values」というデータの受け入れ項目はどのようなデータ形式でも、個数も制限なく受け入れ、すべて明細で表現される、ということになります。

ここでは全ての内容についての説明は難しいため、詳細は[公式の英語ページ](https://github.com/Microsoft/PowerBI-visuals/blob/master/Capabilities/Capabilities.md)か、[非公式の日本語ページ](https://qiita.com/kenakamu/items/46ae6e419c49284c75ed)をご覧のうえ、ご理解頂ければと思います。

---

2. それではまず、「dataRoles」について変更を行いましょう。以下のように既存の内容の変更と、追加の項目を記述します。

```
"dataRoles": [
    {
      "displayName": "値",
      "description": "プロットする値を入力します。連続値、離散値が入力可能です",
      "kind": "GroupingOrMeasure",
      "name": "Values"
    },
    {
      "displayName": "カラー",
      "description": "プロットに色付けする値を入力します。離散値のみが入力可能です（15値まで）",
      "kind": "GroupingOrMeasure",
      "name": "ColorVal"
    }
  ],
```
最初に変更部分です。既存の「Values」という言葉も分かりにくいので「値」など日本語に変更できます。ただし変更するのは「displayName」のみで「name」は変更しないでください。こちらは内部で使用する名称となります。  
また「descriptions」という項目を増やしました。これは「値」の欄でマウス ポイントをホバー（何もクリックせず上に置いてあるだけの状態）した際に表示されるバルーン ヘルプのようなものです。これで投入するデータの種類などに注意を与えられます。

次にグラフに色付けを行うための項目を投入する「カラー」という部分を追記します。こちらも同様に「descriptsions」に注意事項を記入します。ここでは内部名を「ColorVal」としました。

---

3. 続けて追加した「ColorVal」のデータの取り扱いを追記しましょう。

元のコードは以下のとおりです。

```
  "dataViewMappings": [
    {
      "scriptResult": {
        "dataInput": {
          "table": {
            "rows": {
              "select": [
                {
                  "for": {
                    "in": "Values"
                  }
                }
              ],
～中略～
    }
  ],
```

ここに ColorVal 用の処理内容を追記します。

```
  "dataViewMappings": [
    {
      "scriptResult": {
        "dataInput": {
          "table": {
            "rows": {
              "select": [
                {
                  "for": {
                    "in": "Values"
                  }
                },
                {
                  "for": {
                    "in": "ColorVal"
                  }
                }
              ],
～中略～
    }
  ],
```

ここでは「for, in」という方式で「table」にデータを格納しています。「for, in」 はデータを明細のまま扱うことを示します。これ以外にも「bind, to」という1つのフィールドに制限する方式があります。詳細は [DataViewMappingsの説明ページ](https://github.com/Microsoft/PowerBI-visuals/blob/master/Capabilities/DataViewMappings.md) をご覧ください。

変更、追記が終わったらファイルを保存します。

---

4. それでは早速どのように表示されるのか見てみましょう。統合コンソールが表示されていない場合には「表示」->「統合コンソール」をクリックするか、「Ctral+@」を押下します。もし前の章で R のコンソールを起動したままの場合は、コンソールに「quit()」と入力、実行して R のターミナルを閉じます。  
準備ができたら以下のコマンドを実行して pbiviz サーバーを起動します。

`pbiviz start`

---

5. Power BI サービスの画面を開きます。以下のように「値」という項目と「カラー」という項目が表示されていれば問題なく動作していることになります（ただしまだロジックは入れておりませんのでカラー表示はできません）。

<img src="img/VSC25.png" width=360>

---

6. 続けて R のスクリプトにカラー化させる内容を記述してみましょう。「script.r」ファイルを開き、以下の行を変更します。

`ggp = ggpairs(Values)`

以下の内容に変更します。R Studioの際にカラー化した際のコードを一部変更し、先ほど追加した「カラー」項目の内部名「ColorVal」にしました。

`ggp = ggpairs(Values, mapping = aes(color = ColorVal))`

---

7. これで実際に動作を見てみましょう。グラフを再読み込みしてみます。

<img src="img/VSC26.png" width=360>

どうやらエラーのようです。このように R でカスタム ビジュアルを開発する際にはエラー表示はプロット画面のみで表示されますのでご注意ください。詳細は「詳細を確認する」リンクをクリックします。

<img src="img/VSC27.png" width=480>

どうやら「aes」というファンクションが無いというエラーのようです。このように R Studio では表示されなかったエラーが表示されるということは、Power BI の R の処理が一般的な R と異なるということを示します。ここでは明示的に、

`library("ggplot2")`

という行を「Library Declarations」の部分に追記します。以下のようになっていれば問題ありません。

```
############### Library Declarations ###############
#library("progress") <- This moduele not compatible PBI Service
library("ggplot2")
library("showtext")
library("scales")
library("colorspace")
library("GGally")
####################################################
```

この状態でスクリプトを保存します。

---

8. それではもう一度再読み込みしてみましょう。恐らくもう一度エラーが表示されたかと思います。今度のエラー内容も見てみましょう。

<img src="img/VSC28.png" width=480>

これは「ColorVal」が無いため処理できないというエラーです。これは先ほど作成した「カラー」の項目に何も入っていないと起きるエラーです。早速何か離散値のデータを投入します。

<img src="img/VSC29.png" width=480>

データを投入しましたが、またエラーが発生しました。このエラーは連続値のスケールに離散値のデータが入っているため ggplot2 で処理方法が判断できないというものです。このように一見単純なデータを投入しているつもりでも、Power BI 内では目に見えない処理が行われているため、内部的にデータを制限する必要があります。

---

9. 早速コードを変更しましょう。「ColorVal」の最初のカラムだけを受け取り、別の変数に代入してみます。

`graphColor = ColorVal[,1]`

全体としては以下のようになっているはずです。

```
################### Actual code ####################
powerbi_rEnableShowTextForCJKLanguages =  1
graphColor = ColorVal[,1]
ggp = ggpairs(Values, mapping = aes(color = graphColor))
print(ggp, progress = F)
####################################################
```

それでは早速コードを保存して再読み込みしてみましょう。

---

10. うまくカラー化できたようです。しかし途中のエラーからもわかるように、R のコードはそのまま使用してしまうとエラーばかり発生してしまうことになります。続けてエラー ハンドリングも行っていきましょう。

<img src="img/VSC30.png" width=480>

---

11. ここで一旦エラー内容と対応内容を整理しましょう。

|    項目    |              エラー内容               |
|:-----------|:-------------------------------------|
| 1. パッケージ | 依存関係のパッケージが自動的に呼び出されない |
| 2. 追加データ | データが追加されていない時に、定義されていない変数でエラーが起きる |
| 3. データ形式 | 投入データの中で明示的にカラムがしていされていない場合エラーが起きる時がある |

この中で1と3番目は既にハンドリング済みなので、これから2番目の内容を対応しましょう。

---

12. 変数の存在を確認するには `exists` という R の関数を使用します。例えば `ColorVal` という変数の存在を確認するには、

`exists("ColorVal")`

とすることで確認が可能です。それではこの内容を早速コードに組み込んでみましょう。

```
################### Actual code ####################
powerbi_rEnableShowTextForCJKLanguages =  1

if(exists("ColorVal")){
    graphColor = ColorVal[,1]
    ggp = ggpairs(Values, mapping = aes(color = graphColor))
} else {
    ggp = ggpairs(Values)
}

print(ggp, progress = F)
####################################################
```

上記のように if 文に exists を組み込んで、ColorVal がある場合にはカラー、無い場合にはモノクロと分岐させるコードを記述します。  
コードを記述したら保存します。

---

13. この状態で Power BI Service で実行しましょう。グラフを再読み込みします。

<img src="img/VSC30.png" width=480>

先ほどと同じ状態になれば、まずは問題なくコードが動作しているようです。

---

14. 次は「カラー」の項目からデータを除去しましょう。

<img src="img/VSC31.png" width=480>

無事にモノクロになりました。これで無用なエラー画面が表示されずに済みそうです。ただし投入されたデータがグラフと合わない場合などのエラーは発生しますので、必要に応じてエラー ハンドリングを行いましょう。

---

## 7. Power BI のオプションを機能を使用してプロットを構成する
前の章では色付け用のカラムを別に用意し、自由に色付けをできるようにしました。しかしこれだけでは GGally の利点である「グラフの種類を自由に組み合わせる」という機能が利用できません。ここでは Power BI のオプション機能を使用してプロットの構成を行えるようにします。

### ハード コードにするか、選択可能にするか
先ほど「自由に組み合わせる」といいましたが、実は自由に組み合わせることができる = ユーザーが使いやすいとは限りません。もちろんコーディングで値を指定するよりも「選択」するだけで高度な可視化が行えることが望ましいのも事実ですが、自由度を持たせる余りに安定度が低下したり（すぐにエラー画面が表示されるなど）、選択肢が多すぎて逆に何を選択して良いかわからない、または複雑なく組み合わせで開発者も結果が予測できなくなっては本末転倒です。利用者の方が混乱して不安定にするくらいであれば、影響度の少ないパラメータは「ハード コード」してしまうことをお勧めします。  
そこで今回は数あるオプション（例えば ['vignette for ggmatrix'](http://ggobi.github.io/ggally/#ggallyggmatrix) のような）はデフォルトのままで使用せず、右上、斜め、左下部分でのプロット方法の変更だけを選択だけで変更するようにしてみましょう。

---

1. オプションの選択は前の章と同様に「capabilities.json」ファイルに対してと、今回から登場する「src/settings.ts」ファイルに対して行います。先ほどは「capabilities.json」ファイルの「dataRoles」と「dataViewMappings」という部分を変更しましたが、今回は「objects」という部分を変えていきます。元の状態を確認してみましょう。

```
  "objects": {
    "rcv_script": {
      "properties": {
        "provider": {
          "type": {
            "text": true
          }
        },
        "source": {
          "type": {
            "scripting": {
              "source": true
            }
          }
        }
      }
    }
  },
  ```

  このように、rcv_scripts という項目が事前に定義されています。この定義がどのようになっているのか実際の画面で見てみましょう。

---

  2. Power BI サービスの画面を開きます。「視覚化」メニューの下に値を投入するダイアログが表示されていますが、中段の「ペンキ ローラー」アイコンをクリックするとプロパティを設定するダイアログが表示されます。クリックすると以下のように表示されるはずです。

<img src="img/VSC32.png" width=480>

このように、先ほど objects で設定されていた個所が最上段に表示されているかと思います。従って objects にパラメータを設定する箇所を指定することで、このダイヤログを使用して様々なパラメータが設定できることになります。

---

3. 実際にパラメータを設定する領域を作成する前に、どのようなパラメータが設定可能か確認しましょう。objects は、[ここ](https://github.com/Microsoft/PowerBI-visuals/blob/master/Capabilities/Objects.md)から詳細を確認することができます。

ここでも説明されておりますが、Objects は可視化にかかわるカスタマイズ可能なプロパティを割り当てるための記述です。通常は以下のような記述にになります。

```
"objects": {
    "myCustomObject": {
        "displayName": "My Object Name",
        "properties": { ... }
    }
}
```

このように、先ほどの dataRoles と同様に表示名がありますが、変数として利用可能な内部名は、ここでは「myCustomObject」となります。また「properties」という項目があるのがお分かりかと思いますが、ここに実際のパラメータをセットする項目を記述します。セット可能な形式は以下のとおりです。

| 名称 | 記述子形式 | 内容 |
|:----:|:---------:|:-----|
| text | Value     | テキスト形式のパラメータ |
| numeric | Value  | 値型のパラメータ |
| integer | Value  | 整数型のパラメータ |
| bool | Value     | ブーリアン パラメータ |
| fill | Structual | カラー ピッカー |
| enumeration | Structual | パラメータ選択 |

ほとんどのプロパティはそのままの意味ですが、fill はカラー ピッカーを使用できる唯一のプロパティです。また Objects のページに説明はないのですが、enumeration というプロパティを使用するとドロップダウン形式のメニューを作成することが可能になります。今回はこの中で bool と enumeration を使用してパラメータを設定していきます。

---

4. 次に GGally で設定する必要のあるパラメータを確認しましょう。GGally のパラメータ一覧は[こちら](http://ggobi.github.io/ggally/#matrix_sections)にあります。

このページを見るとわかるのは、

- 表示領域は `lower` `upper` `diag` の3つ
- 使用可能なデータ形式は `continuous` `combo` `discrete` の3種類
- それぞれの領域で利用可能な組み合わせは異なるが、`points` `smooth` `density` `cor` `blank` `barDiag` `box` `dot` `facethist` `facetdensity` `denstrip` `ratio` `faacetbar` の13個の表示形式

が利用可能ということになります（ここでは mapping は特殊なので説明を省きます）。ここで設定例を見ると、

```
library(ggplot2)
pm <- ggpairs(
  tips, columns = c("total_bill", "time", "tip"),
  lower = list(
    continuous = "smooth",
    combo = "facetdensity",
    mapping = aes(color = time)
  )
)
pm
```

lower（左下のグラフ表示領域）の `continuous` では `smooth`、`combo` では `facetdensity` の形式で可視化を行うことになります。`mapping` は特殊なパラメータで、`ggplot` に対して直接色付けすることを命令する（aes を介して）というもので、これは前の章の色付けの際に付与したパラメータです。

```pm <- ggpairs(
  tips, columns = c("total_bill", "time", "tip"),
  upper = "blank",
  diag = NULL
)
pm
```

もう一つの例も見てみましょう。`upper` と `diag` がそれぞれ `blank` `NULL` を設定しています。これは「右上」と「斜め」の領域を「非表示」にする設定です。

---

5. それではまず各領域に対して「非表示」にするパラメータを設定してみましょう。capabilities.json を以下のように編集します。

```
  "objects": {
    "rcv_script": {
～中略～
    },
    "PlotSettingsUpper": {
      "displayName": "右上部分の構成",
      "properties": {
        "ShowSw": {
          "displayName": "表示",
          "type": {
            "bool": true
          }
        }
      }
    },
    "PlotSettingsLower": {
      "displayName": "左下部分の構成",
      "properties": {
        "ShowSw": {
          "displayName": "表示",
          "type": {
            "bool": true
          }
        }
      }
    },
    "PlotSettingsDiag": {
      "displayName": "中央部分の構成",
      "properties": {
        "ShowSw": {
          "displayName": "表示",
          "type": {
            "bool": true
          }
        }
      }
    }
  },
  "suppressDefaultTitle": true
}
```

各領域の内部名をそれぞれ `PlotSettingsUpper` `PlotSettingsLower` `PlotSettingsDiag` として、表示名を `displayName` に記述します。そして非表示にするパラメータを、今回は `bool` プロパティ形式を使用しています。`bool` はオン オフ型のスイッチとして表現されるため、表示、非表示を切り替えるようなパラメータにぴったりのプロパティです。  
スイッチにも表示名が設定可能ですので、適宜設定してみてください。  
また、形式は `bool` になっているのはわかると思いますが、その中にある `true` という値はこのパラメータを使用するか否かのブール値となりますので、基本的には常に `true` にしておきます。

---

6. 続けて「src/settings.ts」ファイルも見ていきましょう。

```
module powerbi.extensibility.visual {
    "use strict";
    import DataViewObjectsParser = powerbi.extensibility.utils.dataview.DataViewObjectsParser;

   export class VisualSettings extends DataViewObjectsParser {
      public rcv_script: rcv_scriptSettings = new rcv_scriptSettings();
      }

    export class rcv_scriptSettings {
     // undefined
      public provider     // undefined
      public source     }

}
```

今回は先ほどのファイルと異なり TypeScript 形式のファイルとなります。TypeScript は Javascript を生成するマクロ言語のようなものです。「export class rcv_scriptSettings」の部分を見ると、先ほど既存で設定されていたパラメータ類が存在していることがわかります。この定義を呼び出しているのが「export class VisualSettings extends DataViewObjectsParser」となりますので、この2か所について編集を行う必要があることがわかります。これから編集を行っていきましょう。

---

7. 「src/settings.ts」ファイルを以下のように編集します。

```
module powerbi.extensibility.visual {
  "use strict";
  import DataViewObjectsParser = powerbi.extensibility.utils.dataview.DataViewObjectsParser;

 export class VisualSettings extends DataViewObjectsParser {
  public rcv_script: RcvScriptSettings = new RcvScriptSettings();

  public PlotSettingsUpper: PlotSettingsUpper = new PlotSettingsUpper();
  public PlotSettingsLower: PlotSettingsLower = new PlotSettingsLower();
  public PlotSettingsDiag: PlotSettingsDiag = new PlotSettingsDiag();
    }

  export class RcvScriptSettings {
    // undefined
     public provider;     // undefined
     public source;
  }

  export class PlotSettingsUpper {
    public ShowSw: boolean = true;
  }

  export class PlotSettingsLower {
    public ShowSw: boolean = true;
  }

  export class PlotSettingsDiag {
    public ShowSw: boolean = true;
  }

}
```

settings.ts ファイルについての公式のドキュメントは特に用意されておりませんので、ここでは 
[Tutorial: Funnel Plot from R script to R Custom Visual in Power BI](https://github.com/Microsoft/PowerBI-visuals/tree/master/RVisualTutorial/TutorialFunnelPlot#chapter-31) という R でのカスタム ビジュアルのチュートリアルを参考に変更しております。
各 class 名称は分かりやすいと思いますが、その中にある各パラメターの値も重要です。ここでは表示、非表示を設定するパラメターになりますが、これをデフォルトでオンにする場合には `true` を、オフにする場合には `false` としておく必要があります。その他に設定する値がある場合の例は、後ほど紹介いたします。

この状態で一度保存します。

---

8. それではこの状態で一度 Power BI Service の画面を見てみましょう。

<img src="img/VSC33.png" width=480>

このように「書式」のページに切り替えると、「右上部分の構成」「左下部分の構成「中央部分の構成」というプロパティが表示されているかと思います。そしてそれぞれを展開すると、「表示」というパラメータが「オン」に設定されているのがお分かりになるかと思います。この状態でスイッチを変更してみましょう。切り替えてもグラフには何の影響もありません。  
次にこの変更がグラフに影響を与えるように、R スクリプトに変更を加えます。

---

9. VSCで「script.r」ファイルを開きます。現在のスクリプトの内容を確認しましょう。

```
############### Library Declarations ###############
#library("progress") <- This moduele not compatible PBI Service
library("ggplot2")
library("showtext")
library("scales")
library("colorspace")
library("GGally")
####################################################

################### Actual code ####################
powerbi_rEnableShowTextForCJKLanguages =  1

if(exists("ColorVal")){
    graphColor = ColorVal[,1]
    ggp = ggpairs(Values, mapping = aes(color = graphColor))
} else {
    ggp = ggpairs(Values)
}

print(ggp, progress = F)
####################################################
```

このように、現在は settings.ts や capabilities.json に対するいかなる変更も反映されないようになっています。ここにまず左記ファイルの変更を受け入れる変数を用意します。

```
################### Actual code ####################
powerbi_rEnableShowTextForCJKLanguages =  1
#PBI_PARAM Show the Upper-Right plot area
UshowSw = TRUE
if(exists("PlotSettingsUpper_ShowSw")){
    UshowSw = PlotSettingsUpper_ShowSw
}
#PBI_PARAM Show the Lower-Left plot area
LshowSw = TRUE
if(exists("PlotSettingsLower_ShowSw")){
    LshowSw = PlotSettingsLower_ShowSw
}
#PBI_PARAM Show the Diagonal plot area
DshowSw = TRUE
if(exists("PlotSettingsDiag_ShowSw")){
    DShowSw = PlotSettingsDiag_ShowSw
}

if(exists("ColorVal")){
    graphColor = ColorVal[,1]
    ggp = ggpairs(Values, mapping = aes(color = graphColor))
} else {
    ggp = ggpairs(Values)
}

print(ggp, progress = F)
####################################################
```

上記のように、settings.ts で定義されているクラスを「_」記号で連結して下位のプロパティを呼び出します。例えば、`public PlotSettingsUpper`の下位に定義されている `public ShowSw` を 呼び出すには、`PlotSettingsUpper_ShowSw` のように記述します。  
そして上記変数をここではそれぞれ、`UshowSw`、`LshowSw`、`UshowSw`という変数に格納するようにしました。

続けてこの変数を使用した R のスクリプトを記述してみましょう。

---

10. ここでは前の章で記述した `if(exists("ColorVal")){}` の内容について変更しましょう。パラメータをつなぎ合わせてスクリプト行にすることも可能かと思いますが、ここではコードを分かりやすく見るため、パターンごとにスクリプトを定義しましょう。まず実際にコードを書く前に、どのようなパターンでスクリプトが必要になるか確認します。

| カラー | 右上 | 左下 | 中央 |
|:-----:|:----:|:----:|:----:|
| あり  |  〇  |  〇  |  〇   |
|       |  ×  |  〇  |  〇   |
|       |  〇  |  ×  |  〇   |
|       |  〇  |  〇  |  ×   |
|       |  ×   |  ×  |  〇   |
|       |  ×   |  〇  |  ×   |
|       |  〇  |  ×   |  ×   |
|       |  ×   |  ×   |  ×   |
| 無し  |  

上記の表で見ると、全て表示するものから全非表示まで考えると、8パターンのスクリプトが必要になることがわかります（本来全非表示は不要ですが、ここではわかりやすくするために実装します）。カラーもありと無しがあるので、全部で16パターン必要になります。これを実際コードにすると、以下のようになります。

```
if(exists("ColorVal")){
    graphColor = ColorVal[,1]
    if((UshowSw == FALSE) && (LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", diag = "blank")
    } else if((LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (LshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = "blank")
    } else if(UshowSw == FALSE){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank")
    } else if(LshowSw == FALSE){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), lower = "blank")
    } else if(DshowSw == FALSE) {
        ggp = ggpairs(Values, mapping = aes(color = graphColor), diag = "blank")
    } else ggp = ggpairs(Values, mapping = aes(color = graphColor))
} else {
    if((UshowSw == FALSE) && (LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank",diag = "blank")
    } else if((LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (LshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = "blank")
    } else if(UshowSw == FALSE){
        ggp = ggpairs(Values, upper = "blank")
    } else if(LshowSw == FALSE){
        ggp = ggpairs(Values, lower = "blank")
    } else if(DshowSw == FALSE) {
        ggp = ggpairs(Values, diag = "blank")
    } else ggp = ggpairs(Values)
}
```

ちょっと冗長ですが、これでパターンはわかりやすくなりました。それでは早速コードがちゃんと動作するか確認しましょう。コードを保存してください。

---

11. Power BI Service 上でグラフの自動読み込みを行っていない場合は再読み込みを行ってください。パラメータについては以下のように変更を行うことで、下図のようなグラフに更新されます。

<img src="img/VSC34.png" width=480>

これで無事に表示、非表示の切り替え機能が実装できました。この内容を応用して、他のパラメータについても変更していきましょう。

---

12. それでは表示切替機能と同様に、capabilities.json から変更を行っていきましょう。非常に長くなってしまいますが、以下のように「連続値」「混合値」「離散値」のパラメータを追加して行っていきます。実際にコードを書く前に、一旦内容をまとめてみましょう。

| 表示領域   | 値の種類 | 表示方法                      |
|:---------:|:--------|:------------------------------|
| 右上、左下 | 連続値   | points, smooth, density, cor, blank |
|           | 混合値   | box, dot, facethist, facetdensity, denstrip, blank |
|           | 離散値   | ratio, dacetbar, blank |
|   中央    | 連続値   | densityDiag, barDiag, blankDiag |
|           | 離散値   | barDiag, blankDiag |

`blank` `blankDiag` は先ほどの表示、非表示と似ていますが、各値の種類のみ非表示する機能ですので、これはこのまま利用していきます。
この内容を実際にコードに適用しようとした場合、前掲の例のように、

```
library(ggplot2)
pm <- ggpairs(
  tips, columns = c("total_bill", "time", "tip"),
  lower = list(
    continuous = "smooth",
    combo = "facetdensity",
    mapping = aes(color = time)
  )
)
pm
```

`upper`, `lower`, `diag`それぞれにパラメータを適用するには `list` という命令を使用してリスト形式にしてパラメータ群を指定します。上記の例では、左下表示領域に対して、連続値を `smooth` に、混合値を `facetdensity` に指定しています。グラフのカラー化情報もここに入れる例を掲示していますが、ここではパラメータが複雑化しすぎてしまうので今回は除外しております。興味がある方は、ご自身で実装して試してみてください。

---

13. 情報が整理できたところで、実際にコードを書いてみましょう。下記のように capabilities.json を変更しましょう。

```
  "objects": {
    "rcv_script": {
～中略～
    },
    "PlotSettingsUpper": {
      "displayName": "右上部分の構成",
      "properties": {
        "ShowSw": {
          "displayName": "表示",
          "type": {
            "bool": true
          }
        },
        "Continuous": {
          "displayName": "連続値の扱い(自:他)",
          "type": {
            "enumeration": [
              {
                "displayName": "ポイント",
                "value": "points"
              },
              {
                "displayName": "スムース",
                "value": "smooth"
              },
              {
                "displayName": "密度",
                "value": "density"
              },
              {
                "displayName": "Cor",
                "value": "cor"
              },
              {
                "displayName": "なし",
                "value": "blank"
              }
            ]
          }
        },
        "Combo": {
          "displayName": "混合値の扱い(自:他)",
          "type": {
            "enumeration": [
              {
                "displayName": "ボックス",
                "value": "box"
              },
              {
                "displayName": "ドット",
                "value": "dot"
              },
              {
                "displayName": "ファセットとヒストグラム",
                "value": "fasethist"
              },
              {
                "displayName": "ファセットと密度",
                "value": "fasetdensity"
              },
              {
                "displayName": "denstrip",
                "value": "denstrip"
              },
              {
                "displayName": "なし",
                "value": "blank"
              }
            ]
          }
        },
        "Discrete": {
          "displayName": "離散値の扱い(自:他)",
          "type": {
            "enumeration": [
              {
                "displayName": "比率",
                "value": "ratio"
              },
              {
                "displayName": "ファセットとバー",
                "value": "facetbar"
              },
              {
                "displayName": "なし",
                "value": "blank"
              }
            ]
          }
        }
      }
    },
    "PlotSettingsLower": {
      "displayName": "左下部分の構成",
      "properties": {
        "ShowSw": {
          "displayName": "表示",
          "type": {
            "bool": true
          }
        },
        "Continuous": {
          "displayName": "連続値の扱い(自:他)",
          "type": {
            "enumeration": [
              {
                "displayName": "ポイント",
                "value": "points"
              },
              {
                "displayName": "スムース",
                "value": "smooth"
              },
              {
                "displayName": "密度",
                "value": "density"
              },
              {
                "displayName": "Cor",
                "value": "cor"
              },
              {
                "displayName": "なし",
                "value": "blank"
              }
            ]
          }
        },
        "Combo": {
          "displayName": "混合値の扱い(自:他)",
          "type": {
            "enumeration": [
              {
                "displayName": "ボックス",
                "value": "box"
              },
              {
                "displayName": "ドット",
                "value": "dot"
              },
              {
                "displayName": "ファセットとヒストグラム",
                "value": "fasethist"
              },
              {
                "displayName": "ファセットと密度",
                "value": "fasetdensity"
              },
              {
                "displayName": "denstrip",
                "value": "denstrip"
              },
              {
                "displayName": "なし",
                "value": "blank"
              }
            ]
          }
        },
        "Discrete": {
          "displayName": "離散値の扱い(自:他)",
          "type": {
            "enumeration": [
              {
                "displayName": "比率",
                "value": "ratio"
              },
              {
                "displayName": "ファセットとバー",
                "value": "facetbar"
              },
              {
                "displayName": "なし",
                "value": "blank"
              }
            ]
          }
        }
      }
    },
    "PlotSettingsDiag": {
      "displayName": "中央部分の構成",
      "properties": {
        "ShowSw": {
          "displayName": "表示",
          "type": {
            "bool": true
          }
        },
        "Continuous": {
          "displayName": "連続値の扱い(自:自)",
          "type": {
            "enumeration": [
              {
                "displayName": "密度",
                "value": "densityDiag"
              },
              {
                "displayName": "バー",
                "value": "barDiag"
              },
              {
                "displayName": "なし",
                "value": "blankDiag"
              }
            ]
          }
        },
        "Discrete": {
          "displayName": "離散値の扱い(自:自)",
          "type": {
            "enumeration": [
              {
                "displayName": "バー",
                "value": "barDiag"
              },
              {
                "displayName": "なし",
                "value": "blankDiag"
              }
            ]
          }
        }
      }
    }
  },
```

今回はパラメータ形式として `enumeration` を選択しました。これはドロップダウン方式の選択メニューとなり、ユーザーはマウスで選択するだけでパラメータ内容を指定できるようになります。`enumeration` の選択肢は配列として `displayName` と `value` の組み合わせを保持します。表示名はどのような名称でも問題ありませんが、`value` については実際に使用するパラメータになりますので注意しましょう。

---

14. 続けて settings.ts を編集します。

```
  export class PlotSettingsUpper {
    public ShowSw: boolean = true;
    public Continuous: string = "points";
    public Combo: string = "box";
    public Discrete: string = "facetbar";
  }

  export class PlotSettingsLower {
    public ShowSw: boolean = true;
    public Continuous: string = "points";
    public Combo: string = "box";
    public Discrete: string = "facetbar";
  }

  export class PlotSettingsDiag {
    public ShowSw: boolean = true;
    public Continuous: string = "densityDiag";
    public Discrete: string = "barDiag";
  }
```

ここでも前回の表示切替機能のように、各パラメータに対してデフォルトの値を指定します。ここで指定した値がドロップダウンメニューで選択される値になりますので、使用する機能のデフォルト値に合わせておくか、この後の R スクリプトの変数で指定するデフォルト値と合わせておきましょう。

---

15. R スクリプトを編集する前に、実際に Power BI Service の画面で反映されているか確認しましょう。以下のような画面になっていれば問題なく動作しています。もし表示されない場合には、ブラウザか Power BI Service 上の更新ボタンを使用して画面を更新します。

<img src="img/VSC35.png" width=480>

もちろんここでも操作を行っても反映されませんので、続けて R スクリプトを編集します。

---

16. 以下のように script.r ファイルを編集します。

```
################### Actual code ####################
powerbi_rEnableShowTextForCJKLanguages =  1
#PBI_PARAM Show the Upper-Right plot area
UshowSw = TRUE
if(exists("PlotSettingsUpper_ShowSw")){
    UshowSw = PlotSettingsUpper_ShowSw
}
#PBI_PARAM Show the Lower-Left plot area
LshowSw = TRUE
if(exists("PlotSettingsLower_ShowSw")){
    LshowSw = PlotSettingsLower_ShowSw
}
#PBI_PARAM Show the Diagonal plot area
DshowSw = TRUE
if(exists("PlotSettingsDiag_ShowSw")){
    DshowSw = PlotSettingsDiag_ShowSw
}
#PBI_PARAM Setting for Continuous value on the Upper-Right plot area
UCont = "points"
if(exists("PlotSettingsUpper_Continuous")){
    UCont = PlotSettingsUpper_Continuous
}
#PBI_PARAM Setting for Combination value on the Upper-Right plot area
UCombo = "box"
if(exists("PlotSettingsUpper_Combo")){
    UCombo = PlotSettingsUpper_Combo
}
#PBI_PARAM Setting for Discrete value on the Upper-Right plot area
UDisc = "facetbar"
if(exists("PlotSettingsUpper_Discrete")){
    UDisc = PlotSettingsUpper_Discrete
}
#PBI_PARAM Setting for Continuous value on the Lower-Left plot area
LCont = "points"
if(exists("PlotSettingsLower_Continuous")){
    LCont = PlotSettingsLower_Continuous
}
#PBI_PARAM Setting for Combination value on the Lower-Left plot area
LCombo = "box"
if(exists("PlotSettingsLower_Combo")){
    LCombo = PlotSettingsLower_Combo
}
#PBI_PARAM Setting for Discrete value on the Lower-Left plot area
LDisc = "facetbar"
if(exists("PlotSettingsLower_Discrete")){
    LDisc = PlotSettingsLower_Discrete
}
#PBI_PARAM Setting for Continuous value on the Diagonal plot area
DCont = "densityDiag"
if(exists("PlotSettingsDiag_Continuous")){
    DCont = PlotSettingsDiag_Continuous
}
#PBI_PARAM Setting for Discrete value on the Diagonal plot area
DDisc = "barDiag"
if(exists("PlotSettingsDiag_Discrete")){
    DDisc = PlotSettingsDiag_Discrete
}

if(exists("ColorVal")){
    graphColor = ColorVal[,1]
    if((UshowSw == FALSE) && (LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = "blank")
    } else if((LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (LshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = "blank", diag = list(continuous = DCont, discrete = DDisc))
    } else if(UshowSw == FALSE){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = list(continuous = DCont, discrete = DDisc))
    } else if(LshowSw == FALSE){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = "blank", diag = list(continuous = DCont, discrete = DDisc))
    } else if(DshowSw == FALSE) {
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = "blank")
    } else ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = list(continuous = DCont, discrete = DDisc))
} else {
    if((UshowSw == FALSE) && (LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = "blank")
    } else if((LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (LshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = "blank", diag = list(continuous = DCont, discrete = DDisc))
    } else if(UshowSw == FALSE){
        ggp = ggpairs(Values, upper = "blank", lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = list(continuous = DCont, discrete = DDisc))
    } else if(LshowSw == FALSE){
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = "blank", diag = list(continuous = DCont, discrete = DDisc))
    } else if(DshowSw == FALSE) {
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = "blank")
    } else ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = list(continuous = DCont, discrete = DDisc))
}
```

３行目から57行目まではパラメータの定義を行っています。前の作業で追加した表示、非表示のパラメータの他に、先ほど追加した右上、左下、中央の表示領域での連続値、混合値、離散値のパラメータをそれぞれ定義しています。先ほどの settings.ts でデフォルト値として指定した内容と、例えば `UCont = "points"` のように右上領域の連続値のデフォルト値は `points` というように合わせて指定しましょう。

59行目からは実際の描画を行う部分について変更を行っています。先ほど作成した各パータンの中に、`list()` を使用したパラメータに大して、変数を使用して指定します。

---

17. それでは早速 Power BI Service 上で動作を確認してみましょう。

<img src="img/VSC36.png" width=480>

ここでは「右上」表示部分の「混合値」を「ドット」に変更してみましょう。

<img src="img/VSC37.png" width=480>

無事変更されました。それでは「中央」の「連続値」を「バー」に、「左下」の「離散値」を「なし」に変更してみましょう。

<img src="img/VSC38.png" width=480>

問題なく表示されれば、コードの作成は完了です。最後は作成したこの R コードをパッケージ化することで、Power BI Desktop や Service で利用することが可能です。パッケージ化は R ＋ Plotly 編で行った作業を参考にしてみてください。

18. 実際にパッケージ化してインポートを行うと、以下のように利用できます。「視覚化」メニューに今回作成したパッケージが登録され、次回からはいつでも簡単に SPLOM が利用できるようになります。

<img src="img/VSC39.png" width=480>

以上で R でのカスタム ビジュアルの作成は完了です。  
R を使うことで Azure Machine Learning や ネイティブな Power BI では「そのままでは」行えないアソシエーション分析や、共分散構造分析など、最終結果が図示されるような分析を簡単に行うことができるようになります。  
また、新しいカスタム ビジュアル パッケージは [AppSource に発行](https://docs.microsoft.com/ja-jp/power-bi/developer/office-store)し、[カスタム ビジュアルの 認定](https://docs.microsoft.com/ja-jp/power-bi/power-bi-custom-visuals-certified) を受けることで PowerPoint にエクスポートできるようになったり、サブスクライブ時のレポートに表示されるようになりますので、是非チャレンジしてみてください。
