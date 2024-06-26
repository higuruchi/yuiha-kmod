YuihaFSはユーザの任意のタイミングで任意のファイルのバージョンを作成することができ，
作成したバージョンを木構造で管理できるファイルシステムである．

本ドキュメントでは，YuihaFSのインタフェースと利用例をします．

## YuihaFSのライブラリ

YuihaFSではバージョンの操作を行う際に，YuihaFS独自のフラグを用いる．
`O_VERSION`はopenシステムコールの第2引数に与えることができ，第1引数で与えられたファイルの新たなバージョンを作成する．
`O_PARENT`はopenシステムコールの第２引数に与えることができ，親バージョンを開く，
C言語などのプログラムからYuihaFSの機能を呼び出す際は，以下のコードを追加する．

```C
#define O_VERSION       (1 << 22)
#define O_PARENT        (1 << 23)
```

## バージョン作成

YuihaFSは以下の際に新たなバージョンを作成する．
1. openシステムコール(open(2))にバージョン作成指示フラグ(`O_VERSION`)を与えた場合
2. Trunkバージョン(子バージョンを持つバージョン)を，書き込み可能モードで開いた場合

バージョン作成の例を以下に示す．

```C
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(void)
{
  int fd;
  
  // Create a new file
  fd = open("file_path", O_CREAT);
  close(fd);

  // Create a new leaf version
  fd = open("file_path", O_RDONLY | O_VERSION);
  close(fd);

  // Create a new leaf version based on the parent version
  fd = open("file_path", O_RDWR | O_PARENT);
  close(fd);

  return 0;
}
```

## バージョン一覧取得

バージョンエントリはopenシステムコールによって開かれたバージョンを起点に，
getdentsシステムコールを実行することで取得できる．
`dirent`構造体の`d_type`メンバを用いることで，取得するバージョンエントリの親，兄弟，子バージョンの
選択を行う．
getdentsシステムコールを実行する際に，`d_type`メンバに`DT_PARENT`が設定されている場合は`dirent`構造

getdentsシステムコール毎に親，子もしくは兄弟バージョンのどれかを取得する．

親，子，兄弟バージョンの内どれを取得するかはopenシステムコールの第2引数によって指定できる．

取得するエントリ　親，子，兄弟バージョンのエントリの内
openシステムコールの第1引数にファイルパスを与え，第2引数，第3引数を用いて，
