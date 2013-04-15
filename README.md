# まだ未実装です！！！

# log file checker

## 基本方針

* 1.8.7〜2.0.0対応
* 前回最終確認ポイントの保持
* ファイルサイズが前回最終確認ポイントより小さい場合、ファイルがローテートされたと判断、はじめから実行する
* 条件には「文字列」「正規表現」の二つが使える
* 条件は可変で複数設定可能 
* メソッドを同一名で複数回コールするのもOK

## オプション

```
-t --test     各ファイル 先頭から1Mをパースする（前回実行ポインタを動かさない、出力は強制で標準出力になる）
-a --all      すべてのデータをパースする（前回実行ポインタを動かさない、出力は強制で標準出力になる）
   --no-email 上記オプションと対で使う。email設定していても送信しない
```

## 機能

### 問題行レポート

基本はホワイトリスト。下記のアルゴリズムで抽出された行をまとめてレポート

* white(*args) : ホワイトリストを設定する。条件ヒットした行は抽出されない
* black(*args) : ブラックリスト。もしその条件がヒットした場合はホワイトリスト条件によって抽出対象外となっていたとしても抽出される
* 抽出行がない場合は「(no problem lines)」、 そもそも対象データがない（ファイルサイズが増えてない等）は「(file not changed)」

### サマリーレポート

条件を作成してそれにヒットしたもののカウント、合計等を出力する

* count(:name,*args) : 条件にヒットした回数をカウントする（同一行で複数回ヒットした場合は1回扱い）
* sum(:name, *args) : 条件にヒットしたものの$1を数字として合計する（同一行に複数回同一パターンが出てきた場合は頭のみ）
* gcount(:name,*args) : countの同一行複数回バージョン
* gsum(:name, *args) : sumの同一行複数回バージョン


## 設定ファイル（DSL）

```
# メールでレポートを送信する
email do
  # 送信先
  to   "paco.jp@gmail.com", "someone@example.com"

  # 送信元
  from "report@examplecom"

  # メールの件名（レポートの一行目） 置換文字列が使える 
  # 下記だと%all_sizeで全ログ中の問題行の行数を置換する
  subject "logfile report(error:%all_size)" 
end

# 最終確認状況の保持ファイルのパス設定
# 未設定の場合は「実行DSLファイル名 - 拡張子 + .dat」
datfile "/tmp/logcheck_points.dat"

# 結果出力
# 未設定の場合は標準出力
# out "/tmp/logcheck_points.log"

# fileブロックで対象ファイルを設定します
# 問題行レポートのみサンプル
file "/tmp/batch.log" do
  name  "batch log"
  white /\[INFO.*?\]/
  while 'NO_PROBLEM'
  black 'ERR','CRITICAL' # 可変引数
  black 'FATAL'
end

# 問題行レポートはいらないサンプル
file "/tmp/report.log" do
  name   "report log"
  gcount "yes count", "YES"
end

# まぜまぜサンプル
file "/tmp/money_api.log" do
  name  "api log"

  # whiteを指定すると問題行リポートが作成されます
  white /\[INFO.*?\]/, 'NO_PROBLEM'
  black 'ERR','CRITICAL'
  black 'FATAL' # 複数行に分けてもOK

  # 実行回数と成功回数をとっておく
  count "process count",   'start subscribe with'
  count "succeeded count", /\[\d+\] succeeded/

  # 入金レコードをカウント＆サマリーしておく
  count "paid count",   /paid:\d+\.\d+/
  sum   "paid summary", /paid:(\d+\.\d+)/
end

=begin

# 件名で使用可能な置換文字列例

# 問題行リポートのトータル行数（ログが複数あれば総計）（予約置換文字列）
%all_size
 
# filenameで指定したログファイルの問題行リポートのトータル行数 "%size_" + name
%size_api_log 

# 上で設定したcount:"process count" "%count_" + name
%count_process_count 

# 上で設定したsum:"paid summary" "%sum_" + name
%sum_paid_summary 

# 上で設定したsum:"yes count" "%gcount_" + name
%gcount_yes_count

=end

```

レポートサンプル

```
logfile report(error:5)

############################################################
####                 /tmp/batch.log                     ####
############################################################
file: /tmp/batch.log
--------- lines you need to check ---------
(no problem lines)

############################################################
####                     report log                     ####
############################################################
name: report log
file: /tmp/report.log
yes_count: 14

############################################################
####                      api log                       ####
############################################################
name: api log
file: /tmp/money_api.log)
process count: 100
succeeded count: 120
paid count: 13
paid summary: 2460.23
--------- lines you need to check ---------
some line you have to check hogehogehogehogehogehogehogehoge hogehogehogehogehogehogehogehoge
some line you have to check hogehogehogehogehogehogehogehoge hogehogehogehogehogehogehogehoge
some line you have to check hogehogehogehogehogehogehogehoge hogehogehogehogehogehogehogehoge
some line you have to check hogehogehogehogehogehogehogehoge hogehogehogehogehogehogehogehoge
some line you have to check hogehogehogehogehogehogehogehoge hogehogehogehogehogehogehogehoge

```
