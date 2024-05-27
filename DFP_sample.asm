
;-------------------------------
;����
; �g�p���̓V���A���|�[�g�����L�̐ݒ�ɂ��邱��
;  PC-8001   :�����̃W�����p��1-5�ɂ���
;  PC-8001mk2:�w�ʂ̃W�����p�X�C�b�`��4�ɂ���
;
; �t�H���_����2���̐���
;  (��) "01"
; �t�@�C������3���̐���+".mp3"
;  (��) "001.mp3"
;
;�Q�l�����uKT403A �`�b�v�E�}�j���A���v
;   https://drive.google.com/file/d/1FfOZJdB9Q0GYQllW3_FLckE7aC8jizcE/view
;-------------------------------

DFP_USB			equ	1	;USB
DFP_SD			equ	2	;SD
DFP_CMD_MEDIA		equ	$09	;�Đ�����f�o�C�X��I������
DFP_CMD_RESET		equ	$0C	;�`�b�v�����Z�b�g����
DFP_CMD_PLAY		equ	$0D	;�Đ����J�n����
DFP_CMD_PAUSE		equ	$0E	;�ꎞ��~����
DFP_CMD_PGM		equ	$0F	;�t�H���_�ƃg���b�N�ԍ����w�肵�čĐ�����
DFP_CMD_STOP		equ	$16	;�Đ����~����
DFP_CMD_REPEAT		equ	$19	;���ݍĐ����̃g���b�N���J��Ԃ��Đ�����
DFP_SIZE		equ	10	;�R�}���h�o�C�g��̃T�C�Y
UARTD			equ	$20	;UART �f�[�^�|�[�g
UARTC			equ	UARTD+1	;UART �R���g���[���|�[�g
UART_TIMEOUT		equ	$1000	;�^�C���A�E�g����
TXRDY			equ	0	;���M���f�B�X�e�[�^�X�̃r�b�g�ԍ�
RXRDY			equ	1	;��M���f�B�X�e�[�^�X�̃r�b�g�ԍ�
SYS_KEYWAIT		equ	$0F75
SYS_PRINT		equ 	$52ED	;HL�ȍ~�Ɋi�[���ꂽ������(0�I�[)���o�͂���
SYS_MON			equ	$5C66
SYS_LAST30H		equ	$EA66


	org	$C000

;-------------------------------
;�t�H���_�ԍ�1,�g���b�N�ԍ�2�̋Ȃ����t����f���v���O����
;-------------------------------
DEMO:	CALL	DFP.RESET

	LD	HL,.MES1
	CALL	SYS_PRINT
	CALL	SYS_KEYWAIT

	LD	E,1			;�t�H���_�ԍ�
	LD	D,2			;�g���b�N�ԍ�
	CALL	DFP.PGM			;�t�H���_�ƃg���b�N�ԍ����w�肵�čĐ�����

	LD	HL,.MES2
	CALL	SYS_PRINT
	CALL	SYS_KEYWAIT

	CALL	DFP.STOP		;�Ȃ��~����

	JP	SYS_MON

.MES1:	db	"HIT RETURN KEY TO PLAY",$0D,$0A,0
.MES2:	db	"HIT RETURN KEY TO STOP",$0D,$0A,0


;-------------------------------
;DFPlayer mini �h���C�o
;-------------------------------
DFP:
	;������
.RESET:	LD	A,%01001101		;�{�[���[�g=x1,�L�����N�^��=8�r�b�g,�X�g�b�v�r�b�g=1�r�b�g
	CALL	UART.RESET		;�V���A���|�[�g������������

	LD	A,DFP_CMD_RESET		;�`�b�v�����Z�b�g����
	LD	DE,$0000		;�p�����[�^�͖���
	CALL	.SEND			;�R�}���h���M

	LD	D,DFP_SD		;���Z�b�g���̑I�����f�B�A��SD�ɂ���
;;	JR	.MEDIA

	;�Đ����f�B�A��I������
	; in:D=���f�B�A�ԍ�
.MEDIA:	LD	A,DFP_CMD_MEDIA
	LD	E,0
	JR	.SEND

	;�t�H���_�ƃg���b�N�ԍ����w�肵�čĐ�����
	; in:E=�t�H���_�ԍ�{1~99},D=�g���b�N�ԍ�{1~255}
.PGM:	LD	A,DFP_CMD_PGM
	JR	.SEND

	;��~���̋Ȃ��Đ�����
.PLAY:	LD	A,DFP_CMD_PLAY
	LD	DE,$0000		;�p�����[�^�͖���
	JR	.SEND

	;�Ȃ��ꎞ��~����
.PAUSE:	LD	A,DFP_CMD_PAUSE
	LD	DE,$0000		;�p�����[�^�͖���
	JR	.SEND

	;���s�[�g�Đ��ݒ�ɂ���
	;�Ȃ̍Đ����n�܂��Ă���ݒ肵�Ȃ��Ɣ��f���Ȃ��̂Œ���
.REPEAT:
	LD	A,DFP_CMD_REPEAT
	LD	DE,$0000		;�p�����[�^�͖���
	JR	.SEND

	;�Ȃ��~����
.STOP:	LD	A,DFP_CMD_STOP
	LD	DE,$0000
	JR	.SEND

	;�R�}���h���M
	; in:A=�R�}���h,E=�p�����[�^��ʃo�C�g,D=�p�����[�^���ʃo�C�g
	; out:CY=�G���[�t���O
.SEND:	LD	(.TEMPLATE+3),A
	LD	(.TEMPLATE+5),DE

	;�`�F�b�N�T�������߂�
	;+1�o�C�g�ڂ���6�o�C�g���Ώ�
	LD	DE,.TEMPLATE+1
	LD	HL,$0000
	LD	B,6			;�f�[�^��
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
	SBC	HL,DE			;HL=�`�F�b�N�T��

	LD	A,H
	LD	H,L
	LD	L,A
	LD	(.TEMPLATE+7),HL

	LD	HL,.TEMPLATE
	LD	B,DFP_SIZE
	JP	UART.SEND

	;���M�t�H�[�}�b�g�̃e���v���[�g
	;+3,+5,+6,+7,+8�o�C�g�ڂ�u�������đ��M����
	;
	; +0�o�C�g��=�J�n�R�[�h($7E)
	; +1�o�C�g��=�o�[�W����($FF)
	; +2�o�C�g��=�f�[�^��($06)
	; +3�o�C�g��=�R�}���h
	; +4�o�C�g��=�t�B�[�h�o�b�N�t���O($00=�Ȃ�,$01=����)
	; +5�o�C�g��=�p�����[�^��ʃo�C�g
	; +6�o�C�g��=�p�����[�^���ʃo�C�g
	; +7�o�C�g��=�`�F�b�N�T����ʃo�C�g
	; +8�o�C�g��=�`�F�b�N�T�����ʃo�C�g
	; +9�o�C�g��=�I���R�[�h($EF)
.TEMPLATE:
	db	$7E,$FF,$06,$00,$00,$00,$00,$00,$00,$EF


;-------------------------------
;UART8251 �h���C�o
;-------------------------------
UART:
	;�f�[�^���M
	; in:HL=���M�f�[�^�|�C���^,B=�o�C�g��
	; out:CY=�G���[�t���O
.SEND:	LD	C,UARTD			;�o�͐�̃|�[�g�A�h���X
.L2:	LD	DE,UART_TIMEOUT
.L1:	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,.L3
	SCF				;�^�C���A�E�g������������CY�𗧂ĂĖ߂�
	RET
.L3:	IN	A,(UARTC)		;���MREADY�ɂȂ�܂ő҂�
	AND	1<<TXRDY
	JR	Z,.L1
	OUTI				;�w�肳�ꂽ�o�C�g���̃f�[�^�𑗐M����
	JR	NZ,.L2
	OR	A			;���ׂẴf�[�^�𑗐M������CY���~�낵�Ė߂�
	RET

	;UART���Z�b�g
	; in:A=���[�h���[�h
.RESET:	PUSH	AF			;���[�h���[�h��ޔ�
	XOR	A			;���Z�b�g�̑O�Ƀ_�~�[�f�[�^�𑗐M
	LD	C,UARTC
	OUT	(C),A
	OUT	(C),A
	OUT	(C),A
	LD	A,%01000000		;�������Z�b�g
	OUT	(C),A			;�R�}���h���s
	POP	AF			;���[�h���[�h�𕜋A
	OUT	(C),A			;���[�h�Z�b�g
	LD	A,%00110111		;���M�C�l�[�u��,DTR��LOW,��M�C�l�[�u��,�G���[�t���O�����Z�b�g,RTS��LOW
	OUT	(C),A			;�R�}���h���s

	LD	A,(SYS_LAST30H)		;8251�̐ڑ�����V���A���\�P�b�g�ɕύX����
	AND	%11001111
	OR	%00100000
	LD	(SYS_LAST30H),A
	OUT	($30),A

	RET


