
;-------------------------------
;注意
; 使用時はシリアルポートを下記の設定にすること
;  PC-8001   :内部のジャンパを1-5にする
;  PC-8001mk2:背面のジャンパスイッチを4にする
;
; フォルダ名は2桁の数字
;  (例) "01"
; ファイル名は3桁の数字+".mp3"
;  (例) "001.mp3"
;
;参考資料「KT403A チップ・マニュアル」
;   https://drive.google.com/file/d/1FfOZJdB9Q0GYQllW3_FLckE7aC8jizcE/view
;-------------------------------

DFP_USB			equ	1	;USB
DFP_SD			equ	2	;SD
DFP_CMD_MEDIA		equ	$09	;再生するデバイスを選択する
DFP_CMD_RESET		equ	$0C	;チップをリセットする
DFP_CMD_PLAY		equ	$0D	;再生を開始する
DFP_CMD_PAUSE		equ	$0E	;一時停止する
DFP_CMD_PGM		equ	$0F	;フォルダとトラック番号を指定して再生する
DFP_CMD_STOP		equ	$16	;再生を停止する
DFP_CMD_REPEAT		equ	$19	;現在再生中のトラックを繰り返し再生する
DFP_SIZE		equ	10	;コマンドバイト列のサイズ
UARTD			equ	$20	;UART データポート
UARTC			equ	UARTD+1	;UART コントロールポート
UART_TIMEOUT		equ	$1000	;タイムアウト時間
TXRDY			equ	0	;送信レディステータスのビット番号
RXRDY			equ	1	;受信レディステータスのビット番号
SYS_KEYWAIT		equ	$0F75
SYS_PRINT		equ 	$52ED	;HL以降に格納された文字列(0終端)を出力する
SYS_MON			equ	$5C66
SYS_LAST30H		equ	$EA66


	org	$C000

;-------------------------------
;フォルダ番号1,トラック番号2の曲を演奏するデモプログラム
;-------------------------------
DEMO:	CALL	DFP.RESET

	LD	HL,.MES1
	CALL	SYS_PRINT
	CALL	SYS_KEYWAIT

	LD	E,1			;フォルダ番号
	LD	D,2			;トラック番号
	CALL	DFP.PGM			;フォルダとトラック番号を指定して再生する

	LD	HL,.MES2
	CALL	SYS_PRINT
	CALL	SYS_KEYWAIT

	CALL	DFP.STOP		;曲を停止する

	JP	SYS_MON

.MES1:	db	"HIT RETURN KEY TO PLAY",$0D,$0A,0
.MES2:	db	"HIT RETURN KEY TO STOP",$0D,$0A,0


;-------------------------------
;DFPlayer mini ドライバ
;-------------------------------
DFP:
	;初期化
.RESET:	LD	A,%01001101		;ボーレート=x1,キャラクタ長=8ビット,ストップビット=1ビット
	CALL	UART.RESET		;シリアルポートを初期化する

	LD	A,DFP_CMD_RESET		;チップをリセットする
	LD	DE,$0000		;パラメータは無し
	CALL	.SEND			;コマンド送信

	LD	D,DFP_SD		;リセット時の選択メディアはSDにする
;;	JR	.MEDIA

	;再生メディアを選択する
	; in:D=メディア番号
.MEDIA:	LD	A,DFP_CMD_MEDIA
	LD	E,0
	JR	.SEND

	;フォルダとトラック番号を指定して再生する
	; in:E=フォルダ番号{1~99},D=トラック番号{1~255}
.PGM:	LD	A,DFP_CMD_PGM
	JR	.SEND

	;停止中の曲を再生する
.PLAY:	LD	A,DFP_CMD_PLAY
	LD	DE,$0000		;パラメータは無し
	JR	.SEND

	;曲を一時停止する
.PAUSE:	LD	A,DFP_CMD_PAUSE
	LD	DE,$0000		;パラメータは無し
	JR	.SEND

	;リピート再生設定にする
	;曲の再生が始まってから設定しないと反映しないので注意
.REPEAT:
	LD	A,DFP_CMD_REPEAT
	LD	DE,$0000		;パラメータは無し
	JR	.SEND

	;曲を停止する
.STOP:	LD	A,DFP_CMD_STOP
	LD	DE,$0000
	JR	.SEND

	;コマンド送信
	; in:A=コマンド,E=パラメータ上位バイト,D=パラメータ下位バイト
	; out:CY=エラーフラグ
.SEND:	LD	(.TEMPLATE+3),A
	LD	(.TEMPLATE+5),DE

	;チェックサムを求める
	;+1バイト目から6バイトが対象
	LD	DE,.TEMPLATE+1
	LD	HL,$0000
	LD	B,6			;データ長
.L1:	LD	A,(DE)
	INC	DE
	ADD	A,L			;HL+=A
	LD	L,A
	ADC	A,H
	SUB	L
	LD	H,A
	DJNZ	.L1
	EX	DE,HL
	LD	HL,$0000
	OR	A
	SBC	HL,DE			;HL=チェックサム

	LD	A,H
	LD	H,L
	LD	L,A
	LD	(.TEMPLATE+7),HL

	LD	HL,.TEMPLATE
	LD	B,DFP_SIZE
	JP	UART.SEND

	;送信フォーマットのテンプレート
	;+3,+5,+6,+7,+8バイト目を置き換えて送信する
	;
	; +0バイト目=開始コード($7E)
	; +1バイト目=バージョン($FF)
	; +2バイト目=データ長($06)
	; +3バイト目=コマンド
	; +4バイト目=フィードバックフラグ($00=なし,$01=あり)
	; +5バイト目=パラメータ上位バイト
	; +6バイト目=パラメータ下位バイト
	; +7バイト目=チェックサム上位バイト
	; +8バイト目=チェックサム下位バイト
	; +9バイト目=終了コード($EF)
.TEMPLATE:
	db	$7E,$FF,$06,$00,$00,$00,$00,$00,$00,$EF


;-------------------------------
;UART8251 ドライバ
;-------------------------------
UART:
	;データ送信
	; in:HL=送信データポインタ,B=バイト数
	; out:CY=エラーフラグ
.SEND:	LD	C,UARTD			;出力先のポートアドレス
.L2:	LD	DE,UART_TIMEOUT
.L1:	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,.L3
	SCF				;タイムアウトが発生したらCYを立てて戻る
	RET
.L3:	IN	A,(UARTC)		;送信READYになるまで待つ
	AND	1<<TXRDY
	JR	Z,.L1
	OUTI				;指定されたバイト数のデータを送信する
	JR	NZ,.L2
	OR	A			;すべてのデータを送信したらCYを降ろして戻る
	RET

	;UARTリセット
	; in:A=モードワード
.RESET:	PUSH	AF			;モードワードを退避
	XOR	A			;リセットの前にダミーデータを送信
	LD	C,UARTC
	OUT	(C),A
	OUT	(C),A
	OUT	(C),A
	LD	A,%01000000		;内部リセット
	OUT	(C),A			;コマンド実行
	POP	AF			;モードワードを復帰
	OUT	(C),A			;モードセット
	LD	A,%00110111		;送信イネーブル,DTRをLOW,受信イネーブル,エラーフラグをリセット,RTSをLOW
	OUT	(C),A			;コマンド実行

	LD	A,(SYS_LAST30H)		;8251の接続先をシリアルソケットに変更する
	AND	%11001111
	OR	%00100000
	LD	(SYS_LAST30H),A
	OUT	($30),A

	RET


