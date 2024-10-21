## PC-8001用 DFPlayer mini デモプログラム
`demo.bas`
`demo.wav`

- BASICからDFPlayer miniを操作するためのデモプログラムです
- 使用時はシリアルポートを下記の設定にして下さい
    - PC-8001：内部のジャンパを1-5にする
    - PC-8001mk2：背面のジャンパスイッチを4にする
- あらかじめ使用するメディア内にフォルダを作り、MP3ファイルを書き込んで下さい
- フォルダ名は`01`から`99`まで、MP3ファイル名は`001.mp3`から`255.mp3`まで使用可能です
- 操作コマンドとパラメータはチップ・マニュアルの４ページを参照して下さい

#### 操作例：再生するメディアをUSBメモリにする
    cmd=9
    H=0
    L=1

#### 操作例：フォルダ"01"内のファイル"002.mp3"を演奏する
    cmd=15
    H=1
    L=2

#### 操作例：演奏を停止する
    cmd=22
    H=0
    L=0


## PC-8001用 DFPlayer mini ドライバ
`subroutines.asm`
- デモプログラムで使用されている、DFPlayer miniを操作するための機械語サブルーチンです


## 参考資料

[DFPlayer mini (MP3プレーヤー)](https://akizukidenshi.com/catalog/g/g112544/)

[KT403A チップ・マニュアル](https://drive.google.com/file/d/1FfOZJdB9Q0GYQllW3_FLckE7aC8jizcE/view)
