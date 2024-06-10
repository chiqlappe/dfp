
;-------------------------------
;PC-8001用サブルーチン
;このプログラムはリロケータブルです
;
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

DFP_CMD_MEDIA		equ	$09	;再生するデバイスを選択する
DFP_CMD_RESET		equ	$0C	;チップをリセットする
DFP_USB			equ	1	;USB
DFP_SD			equ	2	;SD
DFP_SIZE		equ	10	;コマンドバイト列のサイズ
UARTD			equ	$20	;UART データポート
UARTC			equ	UARTD+1	;UART コントロールポート
UART_TIMEOUT		equ	$1000	;タイムアウト時間
TXRDY			equ	0	;送信レディステータスのビット番号
RXRDY			equ	1	;受信レディステータスのビット番号

SYS_LAST30H		equ	$EA66
SYS_PRINT		equ 	$52ED	;HL以降に格納された文字列(0終端)を出力する


	org	$E000			;リロケータブル

	JP	DFP.USR_RESET		;+00 初期化ルーチン。最初に一度だけUSR関数でコールする。エラーなら返り値=-1
	JP	DFP.USR_CMD		;+03 コマンド送信ルーチン。コマンドとパラメータをメモリにPOKEしてからUSR関数でコールする。エラーなら返り値=-1


;-------------------------------
;DFPlayer mini ドライバ
;-------------------------------
DFP:

	;送信データ
.DATA:	db	$7E,	; +0バイト目=開始コード($7E)
	db	$FF,	; +1バイト目=バージョン($FF)
	db	$06,	; +2バイト目=データ長($06)
.CMD:	db	$00,	; +3バイト目=コマンド
	db	$00,	; +4バイト目=フィードバックフラグ($00=なし)
.PARAM:	db	$00,	; +5バイト目=パラメータの上位
	db	$00,	; +6バイト目=パラメータの下位
.CSUM:	db	$00,	; +7バイト目=チェックサムの上位
	db	$00,	; +8バイト目=チェックサムの下位
	db	$EF	; +9バイト目=終了コード($EF)

	;USR関数用
	;ポートとチップの初期化
.USR_RESET:
	PUSH	HL			;返り値用にFAC+5を退避

	LD	A,%01001101		;ボーレート=x1,キャラクタ長=8ビット,ストップビット=1ビット
	CALL	UART.RESET		;シリアルポートを初期化する

	LD	HL,$0000
	LD	(.PARAM),HL		;パラメータ
	LD	A,DFP_CMD_RESET		;チップをリセットする
	LD	(.CMD),A
	CALL	.SEND			;out:CY
	JR	NC,.GOOD
;;	JR	.ERROR

.ERROR:	LD	A,$FF			;エラーなら-1を返り値とする
	JR	.EXIT

.GOOD:	LD	A,0			;正常なら0を返り値とする
.EXIT:	POP	HL			;=FAC+5
	LD	(HL),A			;返り値をセットする
	INC	HL
	LD	(HL),A
	RET

	;USR関数用
	;コマンド送信
	; in:A=引数の型,HL=FAC+5,(DFP.PARAM)=パラメータ上位,(DFP.PARAM+1)=パラメータ下位,(DFP.CMD)=コマンド番号
.USR_CMD:
	CP	2
	RET	NZ			;引数が整数型でなければ処理しない

	PUSH	HL			;返り値用にFAC+5を退避

	CALL	.SEND			;out:CY
	JR	NC,.GOOD
	JR	.ERROR

	; in:(DFP.PARAM)=パラメータ上位,(DFP.PARAM+1)=パラメータ下位,(DFP.CMD)=コマンド番号
	; out:CY=エラーフラグ
.SEND:

	;チェックサムを求める
	; +1バイト目から6バイトが対象
	LD	DE,.DATA+1
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
	LD	(.CSUM),HL		;チェックサムをデータにセットする

	LD	HL,.DATA
	LD	B,DFP_SIZE
	JR	UART.SEND		;out:CY


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
.RESET:	PUSH	BC
	PUSH	AF			;モードワードを退避
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

	POP	BC
	RET


