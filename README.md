Grass Translator
----------------

### What is this? / これは何？
This is a program that translates human-friendly script into
[Grass](http://www.blue.sky.or.jp/grass/) program.

人間に読みやすいスクリプトを
[Grass](http://www.blue.sky.or.jp/grass/doc_ja.html)のプログラムに変換するプログラムです。

### Usage / 使い方

    perl grass_trans.pl [number of charcters per line] < input_file > output_file

It reads the script from input\_file (standard input)
and print Grass program to output\_file (standard output).
If there are some message(s) other than character count in standard error,
the content of output file is undefined.

input\_file(標準入力)からスクリプトを読み込み、
output\_file(標準出力)にGrassのプログラムを出力します。
標準エラー出力に文字数カウント以外のメッセージがある場合、出力の内容は未定義です。

### Syntax of the script / スクリプトの文法
This script is case-sensitive.

このスクリプトは大文字と小文字を区別します。

#### Basic stance / 基本的な考え方
Give names to data and be released from counting "w" and "W".

データに名前をつけて、"w"や"W"を数える作業から開放されましょう。

#### Commands / 命令
* function
* endfunction
* rename
* comment_begin
* comment_end

Commands must be written at the beginning of each lines
(indents with tabs/spaces is allowed).

コマンドは各行の最初に書かなければいけません
(タブまたはスペースを用いたインデントをすることはできます)。

#### Comments / コメント

    # comments
    -- comments
    % comments
    // comments
    ' comments
    
    comment_begin
        comments
        comment_begin
            comments
        comment_end
        comments
        # comment_end
        comments
        comments comment_end
        comments
    comment_end


There are five ways to write line comments.
To write block comment, use comment\_begin/comment\_end.
It can be nested.
Please note that since comment\_end is one of the commands,
if it is comment-outed with line comment or not at the beginning of the line,
it doesn't mean the end of block comment.

行コメントの書き方は5種類あります。
ブロックコメントを書くには、comment\_begin/comment\_end命令を使用してください。
これはネスト可能です。
comment\_endは命令の一つであるため、行コメントでコメントアウトされている場合や
行頭にない場合は、ブロックコメントの終わりとみなされないので注意してください。

#### Primitives / プリミティブ

Four names "Out", "Succ", "w", "In" are defined at the beginning of
the script from the initial environment of Grass.
These names can be overwritten.

Grassの初期環境に由来する、"Out", "Succ", "w", "In" の4個の名前が
スクリプトの開始時に定義されています。
これらの名前は上書き可能です。

#### Function application / 関数適用

    [result_name = ]function_name argument1 [argument2 ...]

Calls function function\_name(argument1[,argument2 ...]).
If result\_name is specified, Let result\_name point the created data.
If result\_name is previously defined, it will be overwritten.
At lease one argument is required.

関数function\_name(argument1[,argument2 ...])を呼び出します。
result\_nameが指定されている場合は、それを生成されたデータに設定します。
result\_nameがすでに定義されている場合は上書きされます。
最低1個の引数を指定する必要があります。

#### Function definition / 関数定義

    function function_name argument1 [argument2...]
        # function applications here
    endfunction

Begin function definition with function command and end with endfunction command.
At lease one argument is required.
Function definition can't be nested due to the limitation of Grass.
If function\_name is previously defined, it will be overwrited.
The last result of function applications
(or the last argument if no function applications exists)
will be the return value of the function.
Names of results from function appliationand arguments in function definition
will be invalid and be returned to data at the beginning of function definition.

function命令で関数定義を始め、endfunction命令で終わります。
最低1個の引数を指定する必要があります。
Grassの制約により、関数定義はネストできません。
function\_nameがすでに定義されている場合は上書きされます。
最後の関数適用の結果(関数適用が無い場合は最後の引数)が関数の戻り値になります。
関数定義内の関数適用の結果や引数に割り当てられた名前は
関数定義の終了時に無効になり、関数定義の開始時のデータに戻されます。

#### Give a data new name / データに新しい名前を付ける

    # mv/cd format
    rename old_name new_name
    # assignment format
    rename new_name = old_format

Let new\_name point a data that is pointed by old\_name.
You can use either mv/cd format or assignment format for this command.
old\_name remains valid after this command, but it can be overwrited by
another function definition / function application.
Target which is pointed by old\_name and new\_name isn't synchronized.

new\_nameにold\_nameが指しているデータを指させます。
この命令には、mv/cd形式または代入形式を使用できます。
この命令の後にもold\_nameは有効のままですが、
他の関数定義/関数適用により上書きすることが可能です。
old\_nameとnew\_nameが指す先は同期されません。

#### special name "it" / 特別な名前"it"

"it" is used for pointing the top of stack
(the last result of function definition / function application).

"it"はスタックの最初のデータ(直前の関数定義/関数適用の結果)を指します。

##### example: print "w" and print it again / 例: "w"を出力し、それをまた出力する

    # "_" can be used to express that the name isn't used later.
    # その名前を後で用いないことを示すために、"_"を利用できます。
    # "_" has no special meaning in this script, and is just an name.
    # スクリプト上で"_"は特別な意味を持たず、ただの名前です。
    function _ _
        Out w
        Out it
    endfunction
