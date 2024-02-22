;===============================================================================
;
; ROMPatch.x version 1.24 by �݂� (miyu rose)
;
;  ROMPatch.x ([options]) [filename] ([modelname])
;   [options]
;    -d|u           : ���f����|�@���� �̏����폜���܂�
;    -0|3           : �@���� �� ����|X68030 �ɂ��܂�
;    -A|E|P         : �@���� �� ACE|EXPERT|PRO �ɂ��܂�
;    -S|X|C         : �@���� �� SUPER|XVI|Compact �ɂ��܂�
;    -I|II          : �@���� �� I|II ��t�����܂�
;    -HD|N          : �@���� �� HD ��t��|�������܂�
;    -O|G|B|T       : �@���� �̐F�� �̨���ڰ|��ڰ|��ׯ�|�����ׯ� �ɂ��܂�
;    -eR|eJ|eG|eM|eZ: �Эڰ����� �� ���@|XEiJ|XM6 TypeG|MiSTer|Z �ɂ��܂�
;    -eN            : �Эڰ����� �� �ݒ�Ȃ� �ɂ��܂�
;    -1M|2M|4M|12M  : �w��̕W��������/STD�N���ɂ��܂� (for XEiJ IPLROM)
;    -x             : �N�����S�� X680x0 �ɂ��܂� (for XEiJ IPLROM)
;    -h|?           : �w���v��\�����܂�
;   [filename]
;    �p�b�`�����Ă� IPLROM ($fe0000-$ffffff) �܂���
;    X68KROM ($f00000-$ffffff) �̃_���v�t�@�C���ł�
;   [modelname]
;    �w��̃��f����(X68000 PhantomX ��)�Ƀ��l�[�����܂�
;    �w�肵�Ȃ��ꍇ�͌��ݐݒ蒆�̃��f������\�����܂�
;
;
;  [�Эڰ�����(��)] $00FFFFFE
;  ���@            = $00
;  XEiJ            = $01
;  XM6 TypeG       = $02
;  X68000_MiSTer   = $03
;  X68000 Z        = $0f
;  �ݒ薳��        = $FF
;  �������̒l�͉��ł��B�����ύX�ƂȂ�\��������܂�
;
;  [�@����] $00FFFFFF
;  X68000          = 0b00000000;
;  X68030          = 0b10000000;
;  �ݒ薳��        = 0b11111111;
;
;  ACE             = 0b00010000;
;  EXPERT          = 0b00100000;
;  PRO             = 0b00110000;
;  SUPER           = 0b01000000;
;  XVI             = 0b01010000;
;  COMPACT         = 0b01100000;
;
;  II              = 0b00001000;
;  HD              = 0b00000100;
;
;  OFFICE_GRAY     = 0b00000000;
;  GRAY            = 0b00000001;
;  TITAN_BLACK     = 0b00000010;
;  BLACK           = 0b00000011;
;
;===============================================================================

    .include  doscall.mac
    .cpu  68000

;-------------------------------------------------------------------------------

    .text
    .even

;===============================================================================

main:
    lea.l   mysp,sp

;===============================================================================

title:
    move.w  #$0006,d0                  ; $6 = $2(���F) + $4(����)
    lea.l   mes_title,a0               ; �^�C�g��
    bsr     cprint

    move.w  #$0007,d0                  ; $7 = $3(��)   + $4(����)
    lea.l   mes_version,a0             ; �o�[�W����
    bsr     cprint

    move.w  #$0003,d0                  ; $3(��)
    lea.l   mes_by,a0                  ; by
    bsr     cprint

    move.w  #$0007,d0                  ; $7 = $3(��)   + $4(����)
    lea.l   mes_author,a0              ; ���
    bsr     cprint

    move.w  #$0003,d0                  ; $3(��)
    lea.l   mes_nul,a0
    bsr     cprint

;===============================================================================

arg_check:                             ; �R�}���h���C�������̃`�F�b�N
    addq.l  #1,a2                      ; �����̃T�C�Y�͖���

arg_skip:
    move.b  (a2)+,d0
    cmpi.b  #$00,d0                    ; �����I�[���ȁH
    beq     arg_end                    ; �I�[�Ȃ̂ŏI��
    cmpi.b  #' ',d0
    beq     arg_skip                   ; �X�y�[�X�̓X�L�b�v
    cmpi.b  #'-',d0                    ; '-' ���ȁH
    beq     arg_option                 ; '-' �̓I�v�V���������̃v���t�B�N�X
    cmpi.b  #'/',d0                    ; '/' ���ȁH
    bne     arg_filename               ; '/' ��������I�v�V���������̃v���t�B�N�X������
                                       ; ��������Ȃ��̂ł����ƃt�@�C���l�[��
arg_option:
    move.b  (a2)+,d0
    cmpi.b  #$00,d0                    ; �����I�[���ȁH
    beq     help                       ; �������������̂Ńw���v�\��
    cmpi.b  #'h',d0
    beq     help                       ; -h �� /h �̓w���v�\��
    cmpi.b  #'?',d0
    beq     help                       ; -? �� /? �̓w���v�\��
    cmpi.b  #'d',d0
    beq     arg_flag_delete_name       ; -d �� /D �� ���f�������폜
    cmpi.b  #'u',d0
    beq     arg_flag_unset_modelcode   ; -u �� /U �� �@���ޏ��폜
    cmpi.b  #'0',d0
    beq     arg_flag_X68000            ; -0 �� /0 �� X68000 �t���O
    cmpi.b  #'3',d0
    beq     arg_flag_X68030            ; -3 �� /3 �� X68030 �t���O
    cmpi.b  #'A',d0
    beq     arg_flag_ACE               ; -A �� /A �� ACE �t���O
    cmpi.b  #'E',d0
    beq     arg_flag_EXPERT            ; -E �� /E �� EXPERT �t���O
    cmpi.b  #'P',d0
    beq     arg_flag_PRO               ; -P �� /P �� PRO �t���O
    cmpi.b  #'S',d0
    beq     arg_flag_SUPER             ; -S �� /S �� SUPER �t���O
    cmpi.b  #'X',d0
    beq     arg_flag_XVI               ; -X �� /X �� XVI �t���O
    cmpi.b  #'C',d0
    beq     arg_flag_Compact           ; -C �� /C �� Compact �t���O
    cmpi.b  #'I',d0
    beq     arg_flag_I                 ; -I �� /I �� I �܂��� II �t���O
    cmpi.b  #'H',d0
    beq     arg_flag_H                 ; -H �� /H �� HD �t���O���
    cmpi.b  #'N',d0
    beq     set_flag_N                 ; -N �� /N �� HD �t���O����
    cmpi.b  #'O',d0
    beq     arg_flag_OfficeGray        ; -O �� /O �� OfficeGray �t���O
    cmpi.b  #'G',d0
    beq     arg_flag_Gray              ; -G �� /G �� Gray �t���O
    cmpi.b  #'T',d0
    beq     arg_flag_TitanBlack        ; -T �� /T �� TitanBlack �t���O
    cmpi.b  #'B',d0
    beq     arg_flag_Black             ; -B �� /B �� Black �t���O
    cmpi.b  #'e',d0
    beq     arg_flag_emulatorcode      ; -e �� /e �� �G�~�����[�^�R�[�h
    cmpi.b  #'1',d0
    beq     arg_flag_bootpatch1        ; -1 �� /1 �� �N���p�b�`(1MB/STD)
    cmpi.b  #'2',d0
    beq     arg_flag_bootpatch2        ; -2 �� /2 �� �N���p�b�`(2MB/STD)
    cmpi.b  #'4',d0
    beq     arg_flag_bootpatch4        ; -4 �� /4 �� �N���p�b�`(4MB/STD)
    cmpi.b  #'x',d0
    beq     arg_flag_logopatch         ; -x �� /x �� ���S�p�b�`
    cmpi.b  #' ',d0                    ; �X�y�[�X���ȁH
    beq     arg_skip                   ; �X�y�[�X�Ȃ�X�L�b�v���Ď��̈�����
    bra     arg_option                 ; ���̃I�v�V���������� (-bl �ȂǑ����ď�����Ă��Ή�)

;-------------------------------------------------------------------------------

arg_flag_bootpatch1:                   ; 1MB/STD�N��
    move.b  (a2),d0                    ; �����������擾
    cmpi.b  #'M',d0                    ; �O�̕����Ƃ��킹�� '1M' ���ȁH
    beq     @f                         ; '1M' �������̂Ŏ���

    cmpi.b  #'2',d0                    ; �O�̕����Ƃ��킹�� '12' ���ȁH
    bne     help                       ; '12' ����Ȃ������̂Ńw���v�\��

    addq.l  #1,a2                      ; '12' �������̂ň������ꕶ�������߂�
    move.b  (a2),d0                    ; �����������擾
    cmpi.b  #'M',d0                    ; �O�̕����Ƃ��킹�� '12M' ���ȁH
    bne     help                       ; '12M' ����Ȃ������̂Ńw���v�\��
    
    addq.l  #1,a2                      ; '12M' �������̂ň������ꕶ�������߂�
set_flag_bootpatch12:
    move.b  #1,flag_bootpatch          ; bootpatch �t���O�𗧂Ă�
    lea.l   bootpatch_00,a0
    move.l  #$00C00000,(a0)            ; �������ރf�[�^�� 12MB �ɂ���
    lea.l   mes_bootpatched,a0
    move.b  #'1',(a0)+                 ; �\�����b�Z�[�W��
    move.b  #'2',(a0)+                 ;  12MB
    move.b  #'M',(a0)                  ;   �ɂ���

    bra     arg_option                 ; ���̃I�v�V����������

@@:
    addq.l  #1,a2                      ; '1M' �������̂ň������ꕶ�������߂�
set_flag_bootpatch1:
    move.b  #1,flag_bootpatch          ; bootpatch �t���O�𗧂Ă�
    lea.l   bootpatch_00,a0
    move.l  #$00100000,(a0)            ; �������ރf�[�^�� 1MB �ɂ���
    lea.l   mes_bootpatched,a0
    move.b  #'1',(a0)+                 ; �\�����b�Z�[�W��
    move.b  #'M',(a0)+                 ;  1MB
    move.b  #'B',(a0)                  ;   �ɂ���

    bra     arg_option                 ; ���̃I�v�V����������

arg_flag_bootpatch2:                   ; 2MB/STD�N��
    move.b  (a2),d0                    ; �����������擾
    cmpi.b  #'M',d0                    ; �O�̕����Ƃ��킹�� '2M' ���ȁH
    bne     help                       ; '2M' ����Ȃ������̂Ńw���v�\��
    addq.l  #1,a2                      ; '2M' �������̂ň������ꕶ�������߂�
set_flag_bootpatch2:
    move.b  #2,flag_bootpatch          ; bootpatch �t���O�𗧂Ă�
    lea.l   bootpatch_00,a0
    move.l  #$00200000,(a0)            ; �������ރf�[�^�� 2MB �ɂ���
    lea.l   mes_bootpatched,a0
    move.b  #'2',(a0)+                 ; �\�����b�Z�[�W��
    move.b  #'M',(a0)+                 ;  2MB
    move.b  #'B',(a0)                  ;   �ɂ���

    bra     arg_option                 ; ���̃I�v�V����������

arg_flag_bootpatch4:                   ; 4MB/STD�N��
    move.b  (a2),d0                    ; �����������擾
    cmpi.b  #'M',d0                    ; �O�̕����Ƃ��킹�� '4M' ���ȁH
    bne     help                       ; '4M' ����Ȃ������̂Ńw���v�\��
    addq.l  #1,a2                      ; '4M' �������̂ň������ꕶ�������߂�
set_flag_bootpatch4:
    move.b  #4,flag_bootpatch          ; bootpatch �t���O�𗧂Ă�
    lea.l   bootpatch_00,a0
    move.l  #$00400000,(a0)            ; �������ރf�[�^�� 4MB �ɂ���
    lea.l   mes_bootpatched,a0
    move.b  #'4',(a0)+                 ; �\�����b�Z�[�W��
    move.b  #'M',(a0)+                 ;  4MB
    move.b  #'B',(a0)                  ;   �ɂ���

    bra     arg_option                 ; ���̃I�v�V����������

;-------------------------------------------------------------------------------

arg_flag_logopatch:
    move.b  #1,flag_logopatch          ; logopatch �t���O�𗧂Ă�
    bra     arg_option                 ; ���̃I�v�V����������

;-------------------------------------------------------------------------------

arg_flag_delete_name:
    move.l  #$ffffffff,modelnametag    ; modelnametag ������
    bra     arg_option                 ; ���̃I�v�V����������

;-------------------------------------------------------------------------------

arg_flag_unset_modelcode:
    clr.b   mask_modelcode
    move.b  #$ff,flag_modelcode        ; �@���ޏ����폜
    bra     arg_option

;-------------------------------------------------------------------------------

arg_flag_X68000:
    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode        ; ���� �t���O
    bra     set_flag_bootpatch1        ; 1MB/STD�@����

;-------------------------------------------------------------------------------

arg_flag_ACE:
    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode
    ori.b   #$10,flag_modelcode        ; ACE �t���O
    bra     set_flag_bootpatch1        ; 1MB/STD�@����

;-------------------------------------------------------------------------------

arg_flag_EXPERT:
    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode
    ori.b   #$20,flag_modelcode        ; EXPERT �t���O
    bra     set_flag_bootpatch1        ; 1MB/STD�@����

;-------------------------------------------------------------------------------

arg_flag_PRO:
    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode
    ori.b   #$30,flag_modelcode        ; PRO �t���O
    bra     set_flag_bootpatch1        ; 1MB/STD�@����

;-------------------------------------------------------------------------------

arg_flag_I:
    andi.b  #$f7,mask_modelcode        ; 
    andi.b  #$f7,flag_modelcode        ; I �t���O
    move.b  (a2),d0                    ; �����������擾
    cmpi.b  #'I',d0                    ; �O�̕����Ƃ��킹�� 'II' ���ȁH
    bne     arg_option                 ; 'II' ����Ȃ������̂Ŏ��̃I�v�V����������
    addq.l  #1,a2                      ; 'II' �������̂ň������ꕶ�������߂�
arg_flag_II:
    ori.b   #$08,flag_modelcode        ; II �t���O
    bra     arg_option                 ; ���̃I�v�V����������

;-------------------------------------------------------------------------------

arg_flag_SUPER:
    clr.b   mask_modelcode
    clr.b   flag_modelcode
    ori.b   #$42,flag_modelcode        ; SUPER �t���O
    bra     set_flag_bootpatch2        ; 2MB/STD�@����

;-------------------------------------------------------------------------------

arg_flag_XVI:
    clr.b   mask_modelcode
    clr.b   flag_modelcode
    ori.b   #$52,flag_modelcode        ; XVI �t���O
    bra     set_flag_bootpatch2        ; 2MB/STD�@����

;-------------------------------------------------------------------------------

arg_flag_Compact:
    andi.b  #$80,mask_modelcode
    andi.b  #$80,flag_modelcode
    ori.b   #$62,flag_modelcode        ; Compact (��ڰ) �t���O
    move.b  flag_modelcode,d0
    andi.b  #$80,d0                    ; X68030 �t���O�𒊏o
    beq     set_flag_bootpatch2        ; X68000 Compact �Ȃ̂� 2MB/STD�@����
    ori.b   #$63,flag_modelcode        ; Compact (�����ׯ�) �t���O
    bra     set_flag_bootpatch4        ; X68030 Compact �Ȃ̂� 4MB/STD�@����

;-------------------------------------------------------------------------------

arg_flag_X68030:
    andi.b #$73,mask_modelcode
    ori.b  #$80,flag_modelcode
    bra     set_flag_bootpatch4        ; 4MB/STD�@����

;-------------------------------------------------------------------------------

arg_flag_H:
    move.b  (a2),d0                    ; �����������擾
    cmpi.b  #'D',d0                    ; �O�̕����Ƃ��킹�� 'HD' ���ȁH
    bne     help                       ; 'HD' ����Ȃ������̂Ńw���v�\��
    addq.l  #1,a2                      ; 'HD' �������̂ň������ꕶ�������߂�
set_flag_HD:
    andi.b  #$fb,mask_modelcode
    ori.b   #$04,flag_modelcode        ; HD �t���O
    bra     arg_option                 ; ���̃I�v�V����������
set_flag_N:
    andi.b  #$fb,mask_modelcode
    andi.b  #$fb,flag_modelcode        ; HD �t���O������
    bra     arg_option                 ; ���̃I�v�V����������

;-------------------------------------------------------------------------------

arg_flag_OfficeGray:
    andi.b  #$fc,mask_modelcode
    andi.b  #$fc,flag_modelcode        ; �̨���ڰ ��
    bra     arg_option                 ; ���̃I�v�V����������
arg_flag_Gray:
    andi.b  #$fc,mask_modelcode
    andi.b  #$fc,flag_modelcode        ; ��U �̨���ڰ �ɏ�����
    ori.b   #$01,flag_modelcode        ; ��ڰ ��
    bra     arg_option                 ; ���̃I�v�V����������
arg_flag_Black:
    andi.b  #$fc,mask_modelcode
    ori.b   #$03,flag_modelcode        ; ��ׯ� ��
    bra     arg_option                 ; ���̃I�v�V����������
arg_flag_TitanBlack:
    andi.b  #$fc,mask_modelcode
    andi.b  #$fc,modelcode             ; ��U �̨���ڰ �ɏ�����
    ori.b   #$02,modelcode             ; �����ׯ� ��
    bra     arg_option                 ; ���̃I�v�V����������

;-------------------------------------------------------------------------------
arg_flag_emulatorcode:
    move.b  (a2),d0                    ; �����������擾
    cmpi.b  #'R',d0                    ; �O�̕����Ƃ��킹�� 'eR' ���ȁH
    bne     @f                         ; 'eR' ����Ȃ������̂Ŏ���

    addq.l  #1,a2                      ; 'eR' �������̂ň������ꕶ�������߂�
    move.b  #$00, flag_emulatorcode    ; �Эڰ����ނ� ���@ ��
    bra     arg_option                 ; ���̃I�v�V����������

@@:
    cmpi.b  #'J',d0                    ; �O�̕����Ƃ��킹�� 'eJ' ���ȁH
    bne     @f                         ; 'eJ' ����Ȃ������̂Ŏ���

    addq.l  #1,a2                      ; 'eJ' �������̂ň������ꕶ�������߂�
    move.b  #$01, flag_emulatorcode    ; �Эڰ����ނ� XEiJ ��
    bra     arg_option                 ; ���̃I�v�V����������

@@:
    cmpi.b  #'G',d0                    ; �O�̕����Ƃ��킹�� 'eG' ���ȁH
    bne     @f                         ; 'eG' ����Ȃ������̂Ŏ���

    addq.l  #1,a2                      ; 'eG' �������̂ň������ꕶ�������߂�
    move.b  #$01, flag_emulatorcode    ; �Эڰ����ނ� XM6 TypeG ��
    bra     arg_option                 ; ���̃I�v�V����������

@@:
    cmpi.b  #'G',d0                    ; �O�̕����Ƃ��킹�� 'eG' ���ȁH
    bne     @f                         ; 'eG' ����Ȃ������̂Ŏ���

    addq.l  #1,a2                      ; 'eG' �������̂ň������ꕶ�������߂�
    move.b  #$02, flag_emulatorcode    ; �Эڰ����ނ� XM6 TypeG ��
    bra     arg_option                 ; ���̃I�v�V����������

@@:
    cmpi.b  #'M',d0                    ; �O�̕����Ƃ��킹�� 'eM' ���ȁH
    bne     @f                         ; 'eM' ����Ȃ������̂Ŏ���

    addq.l  #1,a2                      ; 'eM' �������̂ň������ꕶ�������߂�
    move.b  #$03, flag_emulatorcode    ; �Эڰ����ނ� XM6 TypeG ��
    bra     arg_option                 ; ���̃I�v�V����������

@@:
    cmpi.b  #'Z',d0                    ; �O�̕����Ƃ��킹�� 'eZ' ���ȁH
    bne     @f                         ; 'eZ' ����Ȃ������̂Ŏ���

    addq.l  #1,a2                      ; 'eZ' �������̂ň������ꕶ�������߂�
    move.b  #$04, flag_emulatorcode    ; �Эڰ����ނ� Z ��

    andi.b  #$03,mask_modelcode
    andi.b  #$03,flag_modelcode        ; ���� �t���O
    bra     set_flag_bootpatch12       ; 12M/STD�@����

@@:
    cmpi.b  #'N',d0                    ; �O�̕����Ƃ��킹�� 'eN' ���ȁH
    bne     @f                         ; 'eN' ����Ȃ������̂Ŏ���

    addq.l  #1,a2                      ; 'eN' �������̂ň������ꕶ�������߂�
    move.b  #$ff, flag_emulatorcode    ; �Эڰ����ނ� �ݒ�Ȃ� ��
    bra     arg_option                 ; ���̃I�v�V����������

@@:
    bra     help

;-------------------------------------------------------------------------------

arg_filename:
    lea.l filename,a0                  ; �t�@�C�����i�[�|�C���^
    subq.l  #1,a2                      ; �t�@�C�����ꕶ���ڂ�������Ă�̂Ŗ߂�
@@:
    move.b  (a2)+,d0
    cmpi.b  #$00,d0                    ; �����I�[���ȁH
    beq     arg_end                    ; �I�[�Ȃ̂ŏI��
    cmpi.b  #' ',d0                    ; �X�y�[�X���ȁH
    beq     arg_modelname              ; �X�y�[�X�Ȃ瑱���ă��f����
    move.b  d0,(a0)+                   ; �t�@�C������������
    cmpi.b  #$ff,(a0)                  ; ���̏������ݗ\��n�� $ff ���ȁH
    bne     @b                         ; $ff ����Ȃ����烋�[�v
    clr.b   (a0)                       ; $ff �������̂� $00 ����������
arg_filename_toolong
    move.b  (a2)+,d0
    cmpi.b  #$00,d0                    ; �����I�[���ȁH
    beq     arg_end                    ; �I�[�Ȃ̂ŏI��
    cmpi.b  #' ',d0                    ; �X�y�[�X���ȁH
    bne     arg_filename_toolong       ; �X�y�[�X����Ȃ���΃X�L�b�v

;-------------------------------------------------------------------------------

arg_modelname:
    lea.l modelname,a0                 ; ���f�����i�[�|�C���^
@@:
    move.b  (a2)+,d0
    move.b  d0,(a0)+                   ; ���f������������
    cmpi.b  #$00,d0                    ; �����I�[���ȁH
    beq     @f                         ; �I�[�Ȃ̂Ŏ���
    cmpi.b  #$00,(a0)                  ; ���̏������ݗ\��� $00 ���ȁH
    beq     arg_end                    ; $00 �������̂ł���ȏ�͏������݂܂���
    bra     @b                         ; ���[�v
@@:

;-------------------------------------------------------------------------------

arg_end:
    move.b  filename,d0                ; �t�@�C�����͏������܂�Ă邩�ȁH
    beq     help                       ; �������܂�ĂȂ��̂Ńw���v�\��

;===============================================================================

file_ready:
    move.w  #-1,-(sp)                  ; �t�@�C�������擾
    pea.l   filename                   ; �t�@�C����
    DOS     _CHMOD
    addq.l  #6,sp
    or.l    d0,d0                      ; �t�@�C��������
    bpl     @f                         ; �������擾�ł����玟��

file_notfound:
    pea.l   mes_error_notfound         ; �t�@�C�� Not Found
    DOS     _PRINT
    addq.l  #4,sp

    bra     help
@@:

;-------------------------------------------------------------------------------

file_check:
    move.w  d0,-(sp)                   ; �����t�@�C������
    pea.l   filename                   ; �����t�@�C����
    pea.l   filebuffer                 ; �����p�t�@�C���o�b�t�@
    DOS     _FILES
    lea.l   10(sp),sp
    or.l    d0,d0                      ; �G���[�R�[�h��
    bmi     file_notfound              ; ���Ȃ�w��t�@�C�����݂���Ȃ�

;-------------------------------------------------------------------------------

file_check_X68KROM:
    lea.l   filesize,a0                ; �t�@�C���T�C�Y��
    bsr     fetch_l_d0
    cmpi.l  #$00100000,d0              ; $100000 (1,048,576) bytes �ł���
    bne     file_check_IPLROM

    move.b  #1,flag_X68KROM            ; X68KROM.DAT �Ƃ݂Ȃ���
    bra     file_check_attr            ; ����

file_check_IPLROM:
    cmpi.l  #$00020000,d0              ; $020000 (131,072) bytes �ł���
    beq     file_check_attr            ; IPLROM.DAT �Ƃ݂Ȃ��Ď���

file_mismatch:
    pea.l   mes_error_mismatch         ; �p�b�`�ΏۊO
    DOS     _PRINT
    addq.l  #4,sp

    bra     help                       ; �w���v�\��

;-------------------------------------------------------------------------------

file_check_attr:
    move.b  fileattr,d0                ; �t�@�C������
    andi.b  #$01,d0                    ; ���[�h�I�����[�`�F�b�N
    beq     file_open

file_error_readonly:
    pea.l   mes_error_readonly         ; �ǂݎ���p����
    DOS     _PRINT
    addq.l  #4,sp

    bra     help                       ; �w���v�\��

;===============================================================================

file_open:
    move.w  #$0002,-(sp)               ; R/W���[�h
    pea.l   filename                   ; �t�@�C����
    DOS     _OPEN
    addq.l  #6,sp
    move.l  d0,d1                      ; �t�@�C���n���h��
    bpl     file_seekto_top

    pea     mes_error_open             ; �t�@�C���I�[�v���G���[
    DOS     _PRINT
    addq.l  #4,sp

    bra     help

;-------------------------------------------------------------------------------

file_seekto_top:
    clr.w   -(sp)                      ; �t�@�C���̐擪����
    clr.l   -(sp)                      ; �I�t�Z�b�g 0 Byte
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

;-------------------------------------------------------------------------------

file_check_X68KROM_flag:
    move.b  flag_X68KROM,d0            ; X68KROM�t���O��
    beq     @f                         ; �����ĂȂ���΃X�L�b�v

file_case_X68KROM:
    clr.w   -(sp)                      ; �t�@�C���̐擪����
    move.l  #$000e0000,-(sp)           ; �I�t�Z�b�g $e0000 Byte (IPLROM�擪)
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00000000
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[
@@:

;-------------------------------------------------------------------------------

file_seekto_SCSI:                      ; IPLROM $00000000
    move.w  #1,-(sp)                   ; ���݈ʒu (IPLROM�擪����) ����
    move.l  #$00000024,-(sp)           ; �I�t�Z�b�g $24 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00000024
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_check_SCSIINROM:                  ; IPLROM $00000024
    move.l  #6,-(sp)                   ; �ǂݍ��ރT�C�Y $06 Bytes
    pea.l   filebuffer                 ; �ǂݍ��݃o�b�t�@
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _READ                      ; IPLROM $0000002a
    lea     10(sp),sp
    or.l    d0,d0                      ; �ǂݍ��񂾃T�C�Y��
    bmi     file_error_nazo            ; ���Ȃ�G���[

    cmpi.l  #'SCSI',filebuffer         ; SCSIINROM �������Ă� (�܂�ROM30) ���`�F�b�N
    bne     @f                         ; �����ĂȂ��̂� IPLROM �Ƃ݂Ȃ��Ď� (�I�v�V�����`�F�b�N) ��

file_case_ROM30:                       ; SCSIINROM �������Ă����̂ŃT�C�Y�I�� ROM30 �m��
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _CLOSE
    addq.l  #2,sp

    bra     file_mismatch              ; ROM30 �̓p�b�`�ΏۊO
@@:

;-------------------------------------------------------------------------------

file_check_option:
    move.w  flag_bootpatch,d0          ; bootpatch �t���O�� logopatch �t���O���`�F�b�N
    bne     @f                         ; �t���O�w�肠��Ȃ̂Ŏ� (XEiJ �`�F�b�N) ��

file_seekto_modelname1:                ; IPLROM $0000002a
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$0001ffb6,-(sp)           ; �I�t�Z�b�g $1ffb6 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

    bra     file_check_delete_name     ; ���f�����`�F�b�N��
@@:

;-------------------------------------------------------------------------------

file_seekto_XEiJ:                      ; IPLROM $0000002a
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00009fd6,-(sp)           ; �I�t�Z�b�g $9fd6 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0000a000
    addq.l  #8,sp
    or.l    d0,d0                      ; �擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_check_XEiJIPLROM:                 ; IPLROM $0000a000
    move.l  #$10,-(sp)                 ; �ǂݍ��ރT�C�Y
    pea.l   filebuffer                 ; �ǂݍ��݃o�b�t�@
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _READ                      ; IPLROM $0000a010
    lea     10(sp),sp
    or.l    d0,d0                      ; �ǂݍ��񂾃T�C�Y��
    bmi     file_error_nazo            ; ���Ȃ�G���[

    cmpi.l  #'XEiJ',filebuffer         ; XEiJIPLROM ���ǂ����`�F�b�N
    beq     @f                         ; XEiJIPLROM �Ȃ̂Ŏ� (�I�v�V�����ʏ���) ��

    pea.l   mes_skip_option            ; XEiJIPLROM �ł͂Ȃ��̂ŃI�v�V�����������܂���
    DOS     _PRINT
    addq.l  #4,sp

file_seekto_modelname2:                ; IPLROM $0000a010
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00015fd0,-(sp)           ; �I�t�Z�b�g $015fd0 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

    bra     file_check_delete_name     ; ���f����������
@@:

;-------------------------------------------------------------------------------

file_check_bootpatch:                  ; IPLROM $0000a010
    move.b  flag_bootpatch,d0          ; bootpatch �t���O���`�F�b�N
    bne     @f                         ; �t���O�w�肳��Ă���̂Ŏ� (bootpatch����) ��

file_seekto_logopatch1:                ; IPLROM $0000a010
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$000072a4,-(sp)           ; �I�t�Z�b�g $72a4 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $000112b4
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

    bra     file_check_logopatch       ; logopatch������
@@:

;-------------------------------------------------------------------------------

file_seekto_bootpatch_00:              ; IPLROM $0000a010
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$000069e0,-(sp)           ; �I�t�Z�b�g $69e0 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $000109f0
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_bootpatch_00:                     ; IPLROM $000109f0
    move.l  #$08,-(sp)                 ; �㏑���T�C�Y $8 Bytes
    pea.l   bootpatch_00               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $000109f8
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_bootpatch_01:              ; IPLROM $000109f8
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $8 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00010a00
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_bootpatch_01:                     ; IPLROM $00010a00
    move.l  #$02,-(sp)                 ; �㏑���T�C�Y $2 Bytes
    pea.l   bootpatch_01               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00010a02
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_bootpatch_complete:
    pea.l   mes_bootpatched            ; �N���p�b�`����
    DOS     _PRINT
    addq.l  #4,sp

file_seekto_logopatch2:                ; IPLROM $00010a02
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$000008b2,-(sp)           ; �I�t�Z�b�g $8b2 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $000112b4
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

;-------------------------------------------------------------------------------

file_check_logopatch                   ; IPLROM $000112b4
    move.b  flag_logopatch,d0          ; logopatch �t���O���`�F�b�N
    bne     @f                         ; �t���O�w�肳��Ă���̂Ŏ� (logopatch����) ��

file_seekto_modelname3:                ; IPLROM $000112b4
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$0000ed2c,-(sp)           ; �I�t�Z�b�g $ed2c Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

    bra     file_check_delete_name     ; ���f����������
@@:

;-------------------------------------------------------------------------------

file_logopatch_00:                     ; IPLROM $000112b4
    move.l  #$01,-(sp)                 ; �㏑���T�C�Y $1 Bytes
    pea.l   logopatch_00               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $000112b5
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_01:              ; IPLROM $000112b5
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$0000000d,-(sp)           ; �I�t�Z�b�g $0d Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $000112c2
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_01:                     ; IPLROM $000112c2
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_01               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $000112c8
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_02:              ; IPLROM $000112c8
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $000112d0
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_02:                     ; IPLROM $000112d0
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_02               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $000112d6
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_03:              ; IPLROM $000112d6
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $000112de
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_03:                     ; IPLROM $000112de
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_03               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $000112e4
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_04:              ; IPLROM $000112e4
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $000112ec
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_04:                     ; IPLROM $000112ec
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_04               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $000112f2
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_05:              ; IPLROM $000112f2
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $000112fa
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_05:                     ; IPLROM $000112fa
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_05               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00011300
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_06:              ; IPLROM $00011300
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00011308
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_06:                     ; IPLROM $00011308
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_06               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $0001130e
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_07:              ; IPLROM $0001130e
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000005,-(sp)           ; �I�t�Z�b�g $05 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00011313
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_07:                     ; IPLROM $00011313
    move.l  #$09,-(sp)                 ; �㏑���T�C�Y $9 Bytes
    pea.l   logopatch_07               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $0001131c
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_08:              ; IPLROM $0001131c
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00011324
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_08:                     ; IPLROM $00011324
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_08               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $0001132a
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_09:              ; IPLROM $0001132a
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00011332
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_09:                     ; IPLROM $00011332
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_09               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00011338
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_10:              ; IPLROM $00011338
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000007,-(sp)           ; �I�t�Z�b�g $07 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001133f
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_10:                     ; IPLROM $0001133f
    move.l  #$07,-(sp)                 ; �㏑���T�C�Y $7 Bytes
    pea.l   logopatch_10               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00011346
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_11:              ; IPLROM $00011346
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000007,-(sp)           ; �I�t�Z�b�g $07 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001134d
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_11:                     ; IPLROM $0001134d
    move.l  #$07,-(sp)                 ; �㏑���T�C�Y $7 Bytes
    pea.l   logopatch_11               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00011354
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_12:              ; IPLROM $00011354
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000007,-(sp)           ; �I�t�Z�b�g $07 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001135b
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_12:                     ; IPLROM $0001135b
    move.l  #$07,-(sp)                 ; �㏑���T�C�Y $7 Bytes
    pea.l   logopatch_12               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00011362
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_13:              ; IPLROM $00011362
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000007,-(sp)           ; �I�t�Z�b�g $07 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00011369
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_13:                     ; IPLROM $00011369
    move.l  #$07,-(sp)                 ; �㏑���T�C�Y $7 Bytes
    pea.l   logopatch_13               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00011370
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_14:              ; IPLROM $00011370
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00011378
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_14:                     ; IPLROM $00011378
    move.l  #$06,-(sp)                 ; �㏑���T�C�Y $6 Bytes
    pea.l   logopatch_14               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $0001137e
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_seekto_logopatch_15:              ; IPLROM $0001137e
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$00000008,-(sp)           ; �I�t�Z�b�g $08 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $00011386
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_logopatch_15:                     ; IPLROM $00011386
    move.l  #$01,-(sp)                 ; �㏑���T�C�Y $1 Bytes
    pea.l   logopatch_15               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00011387
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

file_logopatch_complete:
    pea.l   mes_logopatched            ; ���S�p�b�`����
    DOS     _PRINT
    addq.l  #4,sp

file_seekto_modelname4:                ; IPLROM $00011387
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #$0000ec59,-(sp)           ; �I�t�Z�b�g $ec59 Bytes
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001ffe0
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

;-------------------------------------------------------------------------------

file_check_delete_name:                ; IPLROM $0001ffe0
    cmpi.l  #$ffffffff,modelnametag    ; ���f�����̃^�O��
    bne     file_check_modelname       ; �����ĂȂ���Ύ� (���f��������) ��

    lea.l  modelname,a0
@@:
    move.b  #$ff,(a0)+                 ; $ff �Ŗ��߂�
    cmpi.b  #$00,(a0)                  ; ���̏������ݗ\��� $00 ���ȁH
    bne     @b                         ; $00 �ł͂Ȃ��̂Ń��[�v

                                       ; IPLROM $0001fffe
    bra     file_patch_modelname       ; ���f�����p�b�`��

;-------------------------------------------------------------------------------

file_check_modelname:
    cmpi.b  #$ff,modelname             ; modelname �w����`�F�b�N
    bne     file_patch_modelname       ; �w�肳��Ă�̂Ń��f�����p�b�`��

;-------------------------------------------------------------------------------

file_read_modelname:                   ; IPLROM $0001ffe0
    move.l  #$1e,-(sp)                 ; �ǂݍ��ރT�C�Y $1e Bytes
    pea.l   modelnametag               ; �ǂݍ��݃o�b�t�@
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _READ                      ; IPLROM $0001fffe
    lea     10(sp),sp
    or.l    d0,d0                      ; �ǂݍ��񂾃T�C�Y��
    bmi     file_error_nazo            ; ���Ȃ�G���[
    
    cmpi.l  #'NAME',modelnametag       ; ���f�����͐ݒ�ρH
    beq     @f                         ; �ݒ肳��Ă���̂Ŏ���

    pea.l   mes_no_modelname           ; ���f�����͖��ݒ�
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_read_emulatorcode     ; �@���� ������
@@:
    pea.l   mes_modelname1             ; ���f����(�O��)
    DOS     _PRINT
    addq.l  #4,sp
    pea.l   modelname                  ; ���f����
    DOS     _PRINT
    addq.l  #4,sp
    pea.l   mes_modelname2             ; ���f����(�㕶)
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_read_emulatorcode     ; �@���� ������

;-------------------------------------------------------------------------------

file_patch_modelname:                  ; IPLROM $0001ffe0
    move.l  #$1e,-(sp)                 ; �㏑���T�C�Y $1e Bytes
    pea.l   modelnametag               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $0001fffe
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

    cmpi.b  #$ff,modelname             ; ���f�����P�����ڂ� $ff ����
    bne     @f                         ; $ff ����Ȃ������̂Ŏ� (���f�����\��) ��

file_modelname_deleted:
    pea.l   mes_modelname_deleted      ; �u���f�������폜���܂����v
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_read_emulatorcode     ; �I��������
@@:
    pea.l   mes_renamed1               ; ���f�����㏑������(�O��)
    DOS     _PRINT
    addq.l  #4,sp

    pea.l   modelname                  ; ���f����
    DOS     _PRINT
    addq.l  #4,sp

    pea.l   mes_renamed2               ; �@���㏑������(�㕶)
    DOS     _PRINT
    addq.l  #4,sp

;-------------------------------------------------------------------------------

file_read_emulatorcode:                ; IPLROM $0001fffe
file_read_modelcode:                   ; 
    move.l  #$02,-(sp)                 ; �ǂݍ��ރT�C�Y $02 Bytes
    pea.l   emulatorcode               ; �ǂݍ��݃o�b�t�@
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _READ                      ; IPLROM $00020000
    lea     10(sp),sp
    or.l    d0,d0                      ; �ǂݍ��񂾃T�C�Y��
    bmi     file_error_nazo            ; ���Ȃ�G���[

    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #-1,-(sp)                  ; �I�t�Z�b�g -1 Byte
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001ffff
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

file_check_emulatorcode:
    cmpi.b  #$80,flag_emulatorcode     ; emulatorlcode ���`�F�b�N
    beq     @f                         ; �w��Ȃ��Ȃ̂Ŏ���

    move.b  flag_emulatorcode,d0       ; �w�肳�ꂽ emulatorcode ��
    move.b  d0,emulatorcode            ; ���f
   
file_patch_emulatorcode:               ; IPLROM $0001ffff
    move.w  #1,-(sp)                   ; ���݈ʒu����
    move.l  #-1,-(sp)                  ; �I�t�Z�b�g -1 Byte
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _SEEK                      ; IPLROM $0001fffe
    addq.l  #8,sp
    or.l    d0,d0                      ; �t�@�C���擪����̃I�t�Z�b�g��
    bmi     file_error_nazo            ; ���Ȃ�G���[

    move.l  #$01,-(sp)                 ; �㏑���T�C�Y $01 Bytes
    pea.l   emulatorcode               ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $0001ffff
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

    pea.l   mes_set_emulatorcode1      ; �@���ޏ㏑������(�O��)
    DOS     _PRINT
    addq.l  #4,sp

    moveq   #$00, d0
    move.b  emulatorcode,d0            ; �@����
    bsr     print_emulatorcode         ; �\��

    pea.l   mes_set_emulatorcode2      ; �@���ޏ㏑������(�㕶)
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_check_modelcode       ; modelcode �`�F�b�N��

@@:
    cmpi.b  #$ff,emulatorcode          ; �Эڰ����� �͐ݒ�ρH
    bne     @f                         ; �ݒ肳��Ă���̂Ŏ���

    pea.l   mes_no_emulatorcode        ; �Эڰ����� �͖��ݒ�
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_check_modelcode
@@:
    pea.l   mes_emulatorcode1          ; �Эڰ�����(�O��)
    DOS     _PRINT
    addq.l  #4,sp

    moveq   #$00, d0
    move.b  emulatorcode,d0            ; �Эڰ�����
    bsr     print_emulatorcode         ; �\��

    pea.l   mes_emulatorcode3          ; �Эڰ�����(�㕶)
    DOS     _PRINT
    addq.l  #4,sp

file_check_modelcode:
    cmpi.b  #$ff,mask_modelcode        ; modelcode �̃}�X�N���`�F�b�N
    bne     file_fix_modelcode         ; ���������Ă���̂Ŏ� (modelcode FIX) ��

    cmpi.b  #$ff,modelcode             ; �@���� �͐ݒ�ρH
    bne     @f                         ; �ݒ肳��Ă���̂Ŏ���

    pea.l   mes_no_modelcode           ; �@���� �͖��ݒ�
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_close                 ; �I��
@@:
    pea.l   mes_modelcode1             ; �@����(�O��)
    DOS     _PRINT
    addq.l  #4,sp

    moveq   #$00, d0
    move.b  modelcode,d0               ; �@����
    bsr     print_modelcode            ; �\��

    pea.l   mes_modelcode3             ; �@����(�㕶)
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_close                 ; �I��

;-------------------------------------------------------------------------------

file_fix_modelcode:                    ; IPLROM $0001ffff
    move.b  mask_modelcode,d0
    and.b   d0,modelcode               ; �}�X�N����
    move.b  flag_modelcode,d0
    or.b    d0,modelcode               ; �p�b�`�����Ă�
    move.b  modelcode,d0

    cmpi.b  #$ff,d0                    ; ���ݒ�I�v�V�������ȁH
    bne     modelcode_check            ; ���ݒ�I�v�V�����ł͂Ȃ��̂ŋ@����������
    
    bra     file_patch_modelcode       ; �@���ނ𖢐ݒ��

modelcode_check:
    andi.b  #$f4,d0
    cmpi.b  #$24,d0                    ; EXPERT HD ���ȁH
    beq     file_fix_Black             ; EXPERT HD �� ��ׯ� �̂�

    andi.b  #$f0,d0
    tst.b   d0                         ; X68000 ���� ���ȁH
    bne     @f                         ; X68000 ���ザ��Ȃ��̂Ŏ���

    andi.b  #$f3,modelcode             ; X68000 ����� I|II �� HD �Ȃ�
    bra     file_fix_modelcolor        ; �F�C��
@@:
    cmpi.b  #$10,d0                    ; ACE ���ȁH
    bne     @f                         ; ACE ����Ȃ��̂Ŏ���

    andi.b  #$f7,modelcode             ; ACE �� I|II �Ȃ�
    bra     file_fix_modelcolor        ; �F�C��
@@:
    cmpi.b  #$20,d0                    ; EXPERT ���ȁH
    bne     @f                         ; EXPERT ����Ȃ��̂Ŏ���

    bra     file_fix_modelcolor        ; �F�C��
@@:
    cmpi.b  #$30,d0                    ; PRO ���ȁH
    bne     @f                         ; PRO ����Ȃ��̂Ŏ���

    bra     file_fix_modelcolor        ; �F�C��
@@:
    cmpi.b  #$40,d0                    ; SUPER ���ȁH
    bne     @f                         ; SUPER ����Ȃ��̂Ŏ���

    andi.b  #$f7,modelcode             ; SUPER �� I|II �Ȃ�
    bra     file_fix_TitanBlack        ; SUPER �� �����ׯ� �̂�
@@:
    cmpi.b  #$50,d0                    ; XVI ���ȁH
    bne     @f                         ; XVI ����Ȃ��̂Ŏ���

    andi.b  #$f7,modelcode             ; XVI �� I|II �Ȃ�
    bra     file_fix_TitanBlack        ; XVI �� �����ׯ� �̂�
@@:
    cmpi.b  #$60,d0                    ; X68000 Compact ���ȁH
    bne     @f                         ; X68000 Compact ����Ȃ��̂Ŏ���

    andi.b  #$f7,modelcode             ; X68000 Compact �� I|II �Ȃ�
    bra     file_fix_Gray              ; X68000 Compact �� ��ڰ �̂�
@@:
    cmpi.b  #$70,d0                    ; X68000 ��@�� ���ȁH
    bne     @f                         ; X68000 ��@�� ����Ȃ��̂Ŏ���

    andi.b  #$03,modelcode             ; X68000 �ɏC��
    bra     file_fix_modelcolor        ; �F�C��
@@:
    cmpi.b  #$80,d0                    ; X68030 ���ȁH
    bne     @f                         ; X68030 ����Ȃ��̂Ŏ���

    andi.b  #$f7,modelcode             ; X68030 �� I|II �Ȃ�
    bra     file_fix_TitanBlack        ; X68030 �� �����ׯ� �̂�
@@:
    cmpi.b  #$e0,d0                    ; X68030 Compact ���ȁH
    bne     @f                         ; X68030 Compact ����Ȃ��̂Ŏ���

    andi.b  #$f7,modelcode             ; X68030 Compact �� I|II �Ȃ�
    bra     file_fix_TitanBlack        ; X68030 Compact �� �����ׯ� �̂�
@@:
    andi.b  #$04,modelcode             ; ��U X68000 ��
    ori.b   #$82,modelcode             ; X68030 �ɏC��
    bra     file_patch_modelcode

file_fix_modelcolor:                   ; ����|ACE|EXPERT|PRO�p�F�␳
    move.b  modelcode,d0               ; �@���ނ��擾
    andi.b  #$03,d0                    ; �F�����o��
    btst.l  #1, d0                     ; �̨���ڰ/��ڰ ���ȁH
    bne     file_fix_Black             ; �Ⴄ�̂���ׯ���

    move.b  modelcode,d0               ; �@��R�[�h���擾
    andi.b  #$fc,d0                    ; ��U �̨���ڰ �ɏ�����
    tst.b   d0                         ; ���ォ��
    bne     file_fix_Gray              ; ���ザ��Ȃ��̂� ��ڰ ��
file_fix_OfficeGray:
    andi.b  #$fc,modelcode             ; �̨���ڰ �ɏC��
    bra     file_patch_modelcode
file_fix_Gray:
    andi.b  #$fc,modelcode             ; ��U �̨���ڰ �ɏ�����
    ori.b   #$01,modelcode             ; ��ڰ �ɏC��
    bra     file_patch_modelcode
file_fix_Black
    andi.b  #$fc,modelcode             ; ��U �̨���ڰ �ɏ�����
    ori.b   #$03,modelcode             ; ��ׯ� ��
    bra     file_patch_modelcode
file_fix_TitanBlack
    andi.b  #$fc,modelcode             ; ��U �̨���ڰ �ɏ�����
    ori.b   #$02,modelcode             ; �����ׯ� ��
file_patch_modelcode:
    move.l  #$01,-(sp)                 ; �㏑���T�C�Y $01 Bytes
    pea.l   modelcode                  ; �㏑���f�[�^
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _WRITE                     ; IPLROM $00020000
    lea     10(sp),sp
    or.l    d0,d0                      ; �������񂾃T�C�Y��
    bmi     file_error_write           ; ���Ȃ�G���[

    cmpi.b  #$ff,modelcode             ; �@���� �͐ݒ�ρH
    bne     @f                         ; �ݒ肳��Ă���̂Ŏ���

file_unset_modelcode:
    pea.l   mes_unset_modelcode        ; �u�@���ނ��폜���܂����v
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_close                 ; �I��������
@@:
    pea.l   mes_set_modelcode1         ; �@���ޏ㏑������(�O��)
    DOS     _PRINT
    addq.l  #4,sp

    moveq   #$00, d0
    move.b  modelcode,d0               ; �@����
    bsr     print_modelcode            ; �\��

    pea.l   mes_set_modelcode2         ; �@���ޏ㏑������(�㕶)
    DOS     _PRINT
    addq.l  #4,sp

;-------------------------------------------------------------------------------

file_complete:
    bra     file_close

;-------------------------------------------------------------------------------

file_error_nazo:
    pea.l   mes_error                  ; ��̃G���[ (_SEEK/_READ �ŃG���[)
    DOS     _PRINT
    addq.l  #4,sp

    bra    file_close

;-------------------------------------------------------------------------------

file_error_write:
    pea.l   mes_error_write            ; �������݃G���[
    DOS     _PRINT
    addq.l  #4,sp

    bra     file_close

;-------------------------------------------------------------------------------

file_close:
    move.w  d1,-(sp)                   ; �t�@�C���n���h��
    DOS     _CLOSE
    addq.l  #2,sp

    DOS     _EXIT

;===============================================================================

help:
    pea.l   mes_help                   ; �w���v
    DOS     _PRINT
    addq.l  #4,sp

    DOS     _EXIT

;===============================================================================

print_emulatorcode:                       ; �Эڰ����ޕ\��
    bsr     printb

    pea.l   mes_emulatorcode2
    DOS     _PRINT
    addq.l  #4,sp

    move.b  emulatorcode,d0               ; �@����
    cmp.b   #$00,d0
    bne     @f

    pea.l   mes_Jikki
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    cmp.b   #$01,d0
    bne     @f

    pea.l   mes_XEiJ
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    cmp.b   #$02,d0
    bne     @f

    pea.l   mes_XM6TypeG
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    cmp.b   #$03,d0
    bne     @f

    pea.l   mes_MiSTer
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    cmp.b   #$04,d0
    bne     @f

    pea.l   mes_Z
    DOS     _PRINT
    addq.l  #4,sp

    rts

@@:
    pea.l   mes_noset
    DOS     _PRINT
    addq.l  #4,sp

    rts

;===============================================================================

print_modelcode:                       ; �@���ޕ\��
    move.b  d0,-(sp)
    bsr    printb

    pea.l  mes_modelcode2
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit7:                  ; X68000|X68030 �t���O
    move.b  (sp),d0
    andi.b  #$80,d0
    bne     @f

    pea.l   mes_X68000                 ; X68000
    bra     @@f
@@:
    pea.l   mes_X68030                 ; X68030
@@:
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit654:                ; ACE|EXPERT|PRO|SUPER|XVI|Compact �t���O
    move.b  (sp),d0
    andi.b  #$70,d0
    beq     print_modelcode_bit3
1:
    cmpi.b  #$10,d0
    bne     2f
    pea.l   mes_ACE                    ; ACE
    bra     @f
2:
    cmpi.b  #$20,d0
    bne     3f
    pea.l   mes_EXPERT                 ; EXPERT
    bra     @f
3:
    cmpi.b  #$30,d0
    bne     4f
    pea.l   mes_PRO                    ; PRO
    bra     @f
4:
    cmpi.b  #$40,d0
    bne     5f
    pea.l   mes_SUPER                  ; SUPER
    bra     @f
5:
    cmpi.b  #$50,d0
    bne     6f
    pea.l   mes_XVI                    ; XVI
    bra     @f
6:
    cmpi.b  #$60,d0
    bne     print_modelcode_end
    pea.l   mes_Compact                ; Compact
@@:
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit3:
    move.b  (sp),d0
    andi.b  #$08,d0
    beq     print_modelcode_bit2

    pea.l   mes_II                     ; II
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit2:
    move.b  (sp),d0
    andi.b  #$04,d0
    beq     print_modelcode_bit10

    pea.l   mes_HD                     ; HD
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_bit10:                 ; OfficeGray|Gray|TitanBlack|Black �t���O
    move.b  (sp),d0
    andi.b  #$03,d0
    bne     1f
0:
    pea.l   mes_OfficeGray             ; �̨���ڰ
    bra     @f
1:
    cmpi.b  #$01,d0
    bne     2f
    pea.l   mes_Gray                   ; ��ڰ
    bra     @f
2:
    cmpi.b  #$02,d0
    bne     3f
    pea.l   mes_TitanBlack             ; �����ׯ�
    bra     @f
3:
    pea.l   mes_Black                  ; ��ׯ�
@@:
    DOS     _PRINT
    addq.l  #4,sp

print_modelcode_end:
    move.b (sp)+,d0
    rts

;===============================================================================

printl:
    move.l  d1,-(sp)
    move.l  d2,-(sp)

    move.l  d0,d1
    moveq   #7,d2                      ; �J�E���^
@@:
    rol.l   #4,d1
    move.l  d1,d0
    bsr     printq
    dbra    d2,@b

    move.l (sp)+,d2
    move.l (sp)+,d1
    rts
;
printb:
    move.l  d0,-(sp)

    ror.l   #4,d0
    bsr     printq
    move.l   (sp),d0
    bsr     printq

    move.l  (sp)+,d0
    rts
;
printq:
    andi.w  #$0f,d0
    ori.w   #$30,d0
    cmpi.w  #$3a,d0
    blt     @f
    addq.w  #7,d0
@@:
    move.w  d0,-(sp)
    DOS     _PUTCHAR
    addq.l  #2,sp

    rts

;===============================================================================

cprint:
    move.w  d0,-(sp)
    move.w  #$0002,-(sp)
    DOS     _CONCTRL
    addq.l  #4,sp

    pea.l   (a0)
    DOS     _PRINT
    addq.l  #4,sp

    rts

;===============================================================================

fetch_l_d0:
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    rts

;===============================================================================

    .data
    .even

;===============================================================================

bootpatch_00:
    .dc.b   $00,$40,$00,$00,$00,$fc,$00,$00
bootpatch_01:
    .dc.b   $00,00
logopatch_00:
    .dc.b               $08
logopatch_01:
    .dc.b               $08,$1f,$f0,$00,$07,$fc
logopatch_02:
    .dc.b               $08,$7f,$f8,$00,$1f,$fe
logopatch_03:
    .dc.b               $10,$e0,$38,$00,$38,$0e
logopatch_04:
    .dc.b               $10,$c0,$18,$00,$30,$06
logopatch_05:
    .dc.b               $32,$c0,$1b,$87,$30,$06
logopatch_06:
    .dc.b               $35,$80,$31,$ce,$60,$0c
logopatch_07:
    .dc.b   $ff,$9f,$fc,$79,$80,$30,$dc,$60,$0c
logopatch_08:
    .dc.b               $79,$80,$30,$f8,$60,$0c
logopatch_09:
    .dc.b               $b1,$80,$30,$70,$40,$0c
logopatch_10:
    .dc.b           $0d,$33,$00,$60,$f0,$c0,$18
logopatch_11:
    .dc.b           $0c,$23,$00,$61,$f0,$c0,$18
logopatch_12:
    .dc.b           $1c,$23,$80,$e3,$b8,$e0,$38
logopatch_13:
    .dc.b           $f8,$43,$ff,$c7,$18,$ff,$f0
logopatch_14:
    .dc.b               $41,$ff,$8e,$1c,$7f,$c0
logopatch_15:
    .dc.b               $40

;-------------------------------------------------------------------------------

    .data
    .even

;-------------------------------------------------------------------------------
flag_bootpatch:
    .ds.b   1
flag_logopatch:
    .ds.b   1
mask_modelcode:
    .dc.b   $ff
flag_emulatorcode:
    .dc.b   $80
flag_modelcode:
    .ds.b   1
flag_X68KROM:
    .ds.b   1
;-------------------------------------------------------------------------------

    .data
    .even

;-------------------------------------------------------------------------------
filebuffer:
    .ds.b   21
fileattr:
    .ds.b   1
filetimedate:
    .ds.b   4
filesize:
    .ds.b   4
filename:
    .dc.b   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .dc.b   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff
    .even
modelnametag:
    .dc.b   'NAME'
modelname:
    .dc.b                   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .dc.b   $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
emulatorcode:
    .dc.b   $00
modelcode:
    .dc.b   $00
mes_error:
    .dc.b   '�ċN�����Ă�����߂Ă��������������܂��I',$0d,$0a,$0d,$0a,$0
mes_error_mismatch:
    .dc.b   '���w��̃t�@�C���̓p�b�`�ΏۊO�ł�(T�tT)',$0d,$0a,$0d,$0a,$0
mes_error_readonly:
    .dc.b   '���w��̃t�@�C���͓ǂݎ���p�����ł�(T�tT)',$0d,$0a,$0d,$0a,$0
mes_error_notfound:
    .dc.b   '���w��̃t�@�C����������܂���(T�tT)',$0d,$0a,$0d,$0a,$0
mes_error_open:
    .dc.b   '�t�@�C�����J���܂���ł���(T�tT)',$0d,$0a,$0d,$0a,$0
mes_error_write:
    .dc.b   '�t�@�C�����X�V�ł��܂���ł���(T�tT)',$0d,$0a,$0d,$0a,$0
mes_skip_option:
    .dc.b   'XEiJ �� IPLROM �ł͂Ȃ����߁A�I�v�V�����w������ǃX���[���܂��I',$0d,$0a,$0d,$0a,$0
mes_bootpatched:
    .dc.b   '4MB/STD�N���ɐݒ肵�܂����I',$0d,$0a,00
mes_logopatched:
    .dc.b   '�N�����S�� X680x0 �ɐݒ肵�܂����I',$0d,$0a,00
mes_modelname_deleted:
    .dc.b   '���f���������폜���܂����I',$0d,$0a,$00
mes_no_modelname:
    .dc.b   '���f������ ���ݒ� �ł��I',$0d,$0a,$00
mes_modelname1:
    .dc.b   '���f������ [',$00
mes_modelname2:
    .dc.b   '] �ł��I',$0d,$0a,$00
mes_renamed1:
    .dc.b   '���f������ [',$00
mes_renamed2:
    .dc.b   '] �ɐݒ肵�܂����I',$0d,$0a,$00
mes_unset_modelcode:
    .dc.b   '�@���ޏ����폜���܂����I',$0d,$0a,$0d,$0a,$00
mes_no_emulatorcode:
    .dc.b   '�Эڰ����ނ� ���ݒ� �ł��I',$0d,$0a,$00
mes_emulatorcode1:
    .dc.b   '�Эڰ����ނ� $',$00
mes_emulatorcode2:
    .dc.b   ' - ',$00
mes_emulatorcode3:
    .dc.b   ' �ł��I',$0d,$0a,$00
mes_set_emulatorcode1:
    .dc.b   '�Эڰ����ނ� $',$00
mes_set_emulatorcode2:
    .dc.b   ' �ɐݒ肵�܂����I',$0d,$0a,$00
mes_no_modelcode:
    .dc.b   '�@���ނ� ���ݒ� �ł��I',$0d,$0a,$0d,$0a,$00
mes_modelcode1:
    .dc.b   '�@���ނ� $',$00
mes_modelcode2:
    .dc.b   ' - ',$00
mes_modelcode3:
    .dc.b   ' �ł��I',$0d,$0a,$0d,$0a,$00
mes_set_modelcode1:
    .dc.b   '�@���ނ� $',$00
mes_set_modelcode2:
    .dc.b   ' �ɐݒ肵�܂����I',$0d,$0a,$0d,$0a,$00
mes_X68000:
    .dc.b   'X68000',$00
mes_X68030:
    .dc.b   'X68030',$00
mes_ACE:
    .dc.b   ' ACE',$00
mes_EXPERT:
    .dc.b   ' EXPERT',$00
mes_PRO:
    .dc.b   ' PRO',$00
mes_SUPER:
    .dc.b   ' SUPER',$00
mes_XVI:
    .dc.b   ' XVI',$00
mes_Compact:
    .dc.b   ' Compact',$00
mes_II:
    .dc.b   ' II',$00
mes_HD:
    .dc.b   '-HD',$00
mes_OfficeGray:
    .dc.b   ' (�̨���ڰ)',$00
mes_Gray:
    .dc.b   ' (��ڰ)',$00
mes_TitanBlack:
    .dc.b   ' (�����ׯ�)',$00
mes_Black:
    .dc.b   ' (��ׯ�)',$00
mes_Jikki:
    .dc.b   '���@',$00
mes_XEiJ:
    .dc.b   'XEiJ',$00
mes_XM6TypeG:
    .dc.b   'XM6 TypeG',$00
mes_MiSTer:
    .dc.b   'MiSTER',$00
mes_Z:
    .dc.b   'X68000 Z',$00
mes_noset:
    .dc.b   '�ݒ�Ȃ�',$00
mes_title:
    .dc.b   'ROMPatch ',$00
mes_version:
    .dc.b   $f3,'v',$f3,'e',$f3,'r',$f3,'s',$f3,'i',$f3,'o',$f3,'n',$f3,' ',$f3,'1',$f3,'.',$f3,'2',$f3,'4',$00
mes_by:
    .dc.b   ' ',$f3,'b',$f3,'y ',$00
mes_author:
    .dc.b   '�݂� (miyu rose)',$0d,$0a,$0d,$0a,$0
mes_help:
    .dc.b   ' ROMPatch.x ([options]) [filename] ([modelname])',$0d,$0a
    .dc.b   '  [options]',$0d,$0a
    .dc.b   '   -d|u           : ���f����|�@���� �̏����폜���܂�',$0d,$0a
    .dc.b   '   -0|3           : �@���� �� ����|X68030 �ɂ��܂�',$0d,$0a
    .dc.b   '   -A|E|P         : �@���� �� ACE|EXPERT|PRO �ɂ��܂�',$0d,$0a
    .dc.b   '   -S|X|C         : �@���� �� SUPER|XVI|Compact �ɂ��܂�',$0d,$0a
    .dc.b   '   -I|II          : �@���� �� I|II ��t�����܂�',$0d,$0a
    .dc.b   '   -HD|N          : �@���� �� HD ��t��|�������܂�',$0d,$0a
    .dc.b   '   -O|G|B|T       : �@���� �̐F�� �̨���ڰ|��ڰ|��ׯ�|�����ׯ� �ɂ��܂�',$0d,$0a
    .dc.b   '   -1M|2M|4M|12M  : �w��̕W��������/STD�N���ɂ��܂�',$0d,$0a
    .dc.b   '   -eR|eJ|eG|eM|eZ: �Эڰ����� �� ���@|XEiJ|XM6 TypeG|MiSTer|Z �ɂ��܂�',$0d,$0a
    .dc.b   '   -eN            : �Эڰ����� �� �ݒ�Ȃ� �ɂ��܂�',$0d,$0a
    .dc.b   '   -x             : �N�����S�� X680x0 �ɂ��܂� (for XEiJ IPLROM)',$0d,$0a
    .dc.b   '   -h             : �w���v��\�����܂�',$0d,$0a
    .dc.b   ' [filename]',$0d,$0a
    .dc.b   '  �p�b�`�����Ă� IPLROM ($fe0000-$ffffff) �܂���',$0d,$0a
    .dc.b   '  X68KROM ($f00000-$ffffff) �̃_���v�t�@�C���ł�',$0d,$0a
    .dc.b   ' [modelname]',$0d,$0a
    .dc.b   '  �w��̃��f����(X68000 PhantomX ��)�Ƀ��l�[�����܂�',$0d,$0a
    .dc.b   '  �w�肵�Ȃ��ꍇ�͌��ݐݒ蒆�̃��f������\�����܂�',$0d,$0a
mes_crlf:
    .dc.b   $0d,$0a
mes_nul:
    .dc.b   $00

;===============================================================================

    .stack
    .even

;===============================================================================

mystack:
    .ds.l   256
mysp:
    .end    main

;===============================================================================
