;===============================================================================
;
; ROMDump.x version 1.25 by みゆ (miyu rose)
;
;  ROMDump.x ([options])
;   [options]
;    f : $F00000-$FFFFFF   X68KROM.DAT をダンプします
;    c : $F00000-$FBFFFF     CGROM.DAT をダンプします
;    3 : $FC0000-$FDFFFF     ROM30.DAT が存在したらダンプします
;    i : $FE0000-$FFFFFF    IPLROM.DAT をダンプします
;    n : $FC0000-$FC1FFF SCSIINROM.DAT が存在したらダンプします
;    x : $EA0020-$EA1FFF SCSIEXROM.DAT が存在したらダンプします
;    a : 上記全てをダンプします
;
;  以下のダンプファイルを作成するプログラムです
;   $F00000-$FFFFFF X68KROM.DAT
;   $F00000-$FBFFFF CGROM.DAT
;   $FC0000-$FDFFFF ROM30.DAT (存在する場合のみ)
;   $FE0000-$FFFFFF IPLROM.DAT
;   $FC0000-$FC1FFF SCSIINROM.DAT (存在する場合のみ)
;   $EA0020-$EA1FFF SCSIEXROM.DAT (存在する場合のみ)
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
    
    move.w  #$0006,d0                  ; $6 = $2(黄色) + $4(太字)
    lea.l   mes_title,a0               ; タイトル
    bsr     cprint

    move.w  #$0007,d0                  ; $7 = $3(白)   + $4(太字)
    lea.l   mes_version,a0             ; バージョン
    bsr     cprint

    move.w  #$0003,d0                  ; $3(白)
    lea.l   mes_by,a0                  ; by
    bsr     cprint

    move.w  #$0007,d0                  ; $7 = $3(白)   + $4(太字)
    lea.l   mes_author,a0              ; 作者
    bsr     cprint

    move.w  #$0003,d0                  ; $3(白)
    lea.l   mes_nul,a0
    bsr     cprint

;===============================================================================

arg_check:                             ; コマンドライン引数のチェック
    addq.l  #1,a2                      ; 引数のサイズは無視

arg_loop:                              ; コマンドライン引数処理ルーチン
    move.b  (a2)+,d0                   ; 引数を１文字フェッチ
    cmpi.b  #' ',d0                    ; スペースかな？
    beq     arg_loop                   ; スペース なら スキップ
    ori.b   #$20,d0                    ; 英字小文字化
    cmpi.b  #'c',d0                    ; 'c' かな？
    beq     option_CGROM               ; 'c' なら CGROM.DAT 指定
    cmpi.b  #'3',d0                    ; '3' かな？
    beq     option_ROM30               ; '3' なら ROM30.DAT 指定
    cmpi.b  #'i',d0                    ; 'i' かな？
    beq     option_IPLROM              ; 'i' なら IPLROM.DAT 指定
    cmpi.b  #'n',d0                    ; 'n' かな？
    beq     option_SCSIINROM           ; 'n' なら SCSIINROM.DAT 指定
    cmpi.b  #'x',d0                    ; 'x' かな？
    beq     option_SCSIEXROM           ; 'x' なら SCSIEXROM.DAT 指定
    cmpi.b  #'f',d0                    ; 'f' かな？
    beq     option_X68KROM             ; 'f' なら X68KROM.DAT 指定
    cmpi.b  #'a',d0                    ; 'a' かな？
    beq     option_all                 ; 'a' なら 全ROM 指定

    bra     option_check               ; 引数チェックへ

option_CGROM:
    ori.b   #$01, flg_option           ; CGROM 指定オプションを立てる
    bra     arg_loop                   ; 引数処理へ戻る

option_ROM30:
    ori.b   #$02, flg_option           ; ROM30 指定オプションを立てる
    bra     arg_loop                   ; 引数処理へ戻る

option_IPLROM:
    ori.b   #$04, flg_option           ; IPLROM 指定オプションを立てる
    bra     arg_loop                   ; 引数処理へ戻る

option_SCSIINROM:
    ori.b   #$10, flg_option           ; SCSIINROM 指定オプションを立てる
    bra     arg_loop                   ; 引数処理へ戻る

option_SCSIEXROM:
    ori.b   #$20, flg_option           ; SCSIEXROM 指定オプションを立てる
    bra     arg_loop                   ; 引数処理へ戻る

option_X68KROM:
    ori.b   #$80, flg_option           ; X68KROM 指定オプションを立てる
    bra     arg_loop                   ; 引数処理へ戻る

option_all:                            ; 全ROM 指定オプションを立てる
    ori.b   #$B7, flg_option
    bra     arg_loop                   ; 引数処理へ戻る

option_check:
    tst.b   flg_option                 ; 引数指定確認
    bne     arg_end                    ; 指定されてたらメインルーチンへ

;-------------------------------------------------------------------------------

help:
    pea.l   mes_help                   ; ヘルプメッセージ
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp

    DOS     _EXIT                      ; 終了


arg_end:

;===============================================================================

SUPERVISORMODE:
    clr.l   -(sp)                      ; スーパーバイザーモード
    DOS     _SUPER
    or.l    d0,d0                      ; 元の SSP アドレスが
    bpl     @f                         ; 正しく取得できたら成功なので次へ

;-------------------------------------------------------------------------------

    pea.l   mes_error                  ; 予期せぬ謎エラー
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp

    DOS     _EXIT                      ; 終了

@@:

;-------------------------------------------------------------------------------

    move.l  d0, (sp)                   ; SUPER VISOR モードになれたので SSP 保存

;===============================================================================

X68KROM:
    btst.b  #7, flg_option             ; X68KROM 指定オプションを確認
    beq     @f                         ; 指定されてなければ次へ

    move.l  #$F00000,d0                ; X68KROM の先頭アドレス
    move.l  #$100000,d1                ; X68KROM のサイズ
    move.l  #filename_X68KROM,d2       ; X68KROM のファイル名
    bsr     dump                       ; ダンプ

@@:

;-------------------------------------------------------------------------------

CGROM:
    btst.b  #0, flg_option             ; CGROM 指定プションを確認
    beq     @f                         ; 指定されてなければ次へ

    move.l  #$F00000,d0                ; CGROM の先頭アドレス
    move.l  #$0C0000,d1                ; CGROM のサイズ
    move.l  #filename_CGROM,d2         ; X68KROM のファイル名
    bsr     dump                       ; ダンプ

@@:

;-------------------------------------------------------------------------------

IPLROM:
    btst.b  #2, flg_option             ; IPLROM 指定オプションを確認
    beq     @f                         ; 指定されてなければ次へ

    move.l  #$FE0000,d0                ; IPLROM の先頭アドレス
    move.l  #$020000,d1                ; IPLROM のサイズ
    move.l  #filename_IPLROM,d2        ; IPLROM のファイル名
    bsr     dump                       ; ダンプ

@@:

;-------------------------------------------------------------------------------

ROM30:
    btst.b  #1, flg_option             ; ROM30 指定オプションを確認
    beq     @f                         ; 指定されてなければ次へ

    movea.l #$00FC023C,a0              ; IPLROM 1.5 の ROM30 Human チェック
    cmpi.l  #'uman',(a0)
    beq     ROM30_dump

    movea.l #$00FC203C,a0              ; IPLROM 1.6 の ROM30 Human チェック
    cmpi.l  #'uman',(a0)
    beq     ROM30_dump                 ; ROM30 Human がみつかったのでダンプ

    pea.l   filename_ROM30             ; ファイル名 
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp
    pea.l   mes_santen                 ; 三点リーダー
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp
    pea.l   mes_dontexist              ; 存在しませんでした
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp

    bra     @f                         ; 次へ

ROM30_dump:
    move.l  #$FC0000,d0                ; ROM30 の先頭アドレス
    move.l  #$020000,d1                ; ROM30 のサイズ
    move.l  #filename_ROM30,d2         ; ROM30 のファイル名
    bsr     dump                       ; ダンプ
;   bra     @@f

@@:

;-------------------------------------------------------------------------------

SCSIINROM:
    btst.b  #4, flg_option             ; SCSIINROM 指定オプションを確認
    beq     @f                         ; 指定されてなければ次へ

    movea.l #$00FC0024,a0              ; SCSIINROM 存在チェック
    cmpi.l  #'SCSI',(a0)
    beq     SCSIINROM_dump             ; SCSIINROM が存在すればダンプ

    pea.l   filename_SCSIINROM         ; ファイル名
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp
    pea.l   mes_santen                 ; 三点リーダー
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp
    pea.l   mes_dontexist              ; 存在しませんでした
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp

    bra     @f                         ; 次へ

SCSIINROM_dump
    move.l  #$FC0000,d0                ; SCSIINROM の先頭アドレス
    move.l  #$002000,d1                ; SCSIINROM のサイズ
    move.l  #filename_SCSIINROM,d2     ; SCSIINROM のファイル名
    bsr     dump                       ; ダンプ

@@:

;-------------------------------------------------------------------------------

SCSIEXROM:
    btst.b  #5, flg_option             ; SCSIEXROM 指定オプションを確認
    beq     @f                         ; 指定されてなければ次へ

BUSERROR_hook:
    move.l  sp,a2                      ; spを退避
    move.l  $0008.w,a1                 ; バスエラーのベクタを退避
    lea.l   BUSERROR_resume(pc),a0     ; ベクタの変更先アドレス
    move.l  a0,$0008.w                 ; バスエラーのベクタを書き換え

    moveq.l #0, d2                     ; ファイル名アドレス格納用の d2 レジスタを初期化
    movea.l #$00EA0044,a0
    cmpi.l  #'SCSI',(a0)               ; SCSIボードがささっていない場合はバスエラーでスキップ
    bne     BUSERROR_resume            ; SCSIEXROM を認識できない場合もスキップ

    move.l  #$00EA0020,d0              ; SCSIEXROM の先頭アドレス
    move.l  #$001FE0,d1                ; SCSIEXROM のサイズ
    move.l  #filename_SCSIEXROM,d2     ; SCSIEXROM のファイル名
    bsr     dump                       ; ダンプ

BUSERROR_resume:
    move.l  a2,sp                      ; spを復元
    move.l  a1,$0008.w                 ; バスエラーのベクタを復元

    tst.l   d2                         ; ファイル名は指定されているかな？＝SCSIEXROMは存在してたかな？
    bne     @f                         ; SCSIEXROM が存在していたので次へ

    pea.l   filename_SCSIEXROM         ; ファイル名 
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp
    pea.l   mes_santen                 ; 三点リーダー
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp
    pea.l   mes_dontexist              ; 存在しませんでした
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp

@@:

;===============================================================================

USERMODE:
    DOS     _SUPER                     ; ユーザーモードへ
    addq.l  #4,sp

complete:
    pea.l   mes_crlf                   ; 改行コード
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp

    DOS     _EXIT                      ; 終了

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

dump:
    move.l  d1,-(sp)                   ; 開始アドレス
    move.l  d0,-(sp)                   ; サイズ
    clr.w   -(sp)                      ; ファイル属性(作成後はファイルハンドル)
    move.l  d2,-(sp)                   ; ファイル名
    DOS     _PRINT
    pea.l   mes_santen                 ; 三点リーダー
    DOS     _PRINT                     ; 表示
    addq.l  #4,sp
    DOS     _CREATE
    or.l    d0,d0                      ; ファイルハンドルが
    bmi     dump_failure               ; 負なら作成失敗

dump_success:
    addq.l  #4,sp
    move.w  d0,(sp)                    ; ファイルハンドル(_CREATE の返り値)
    DOS     _WRITE                     ; 書き込み
    DOS     _CLOSE
    pea.l   mes_create                 ; ファイル作成完了メッセージ
    DOS     _PRINT                     ; 表示
    lea.l   14(sp),sp
    moveq.l #0, d0                     ; 成功時の返り値 d0 : 0
    rts

dump_failure:                          ; 作成失敗
    pea.l   mes_cantcreate             ; ファイル作成失敗メッセージ
    DOS     _PRINT                     ; 表示
    lea.l   18(sp),sp
    moveq.l #-1,d0                     ; 失敗時の返り値 d0 : -1
    rts
;===============================================================================

    .data
    .even

;===============================================================================

flg_option:
    .dc.b   $00

;===============================================================================

    .data
    .even

;===============================================================================

filename_X68KROM:
    .dc.b   'X68KROM.DAT',$00
filename_CGROM:
    .dc.b   'CGROM.DAT',$00
filename_IPLROM:
    .dc.b   'IPLROM.DAT',$00
filename_ROM30:
    .dc.b   'ROM30.DAT',$00
filename_SCSIINROM:
    .dc.b   'SCSIINROM.DAT',$00
filename_SCSIEXROM:
    .dc.b   'SCSIEXROM.DAT',$00
mes_santen:
    .dc.b   ' … ',$00
mes_create:
    .dc.b   '作成完了ですヽ(=´▽`=)ﾉ',$0D,$0A,$00
mes_cantcreate:
    .dc.b   '作成できませんでした(TдT)',$0D,$0A,$00
mes_dontexist:
    .dc.b   '存在しませんでした(TдT)',$0D,$0A,$00
mes_error:
    .dc.b   '再起動してから改めてお試しくださいませ！',$0D,$0A,$0D,$0A,$00
mes_title:
    .dc.b   'ROMDump ',$00
mes_version:
    .dc.b   $F3,'v',$F3,'e',$F3,'r',$F3,'s',$F3,'i',$F3,'o',$F3,'n',$F3,' ',$F3,'1',$F3,'.',$F3,'2',$F3,'5',$00
mes_by:
    .dc.b   ' ',$F3,'b',$F3,'y ',$00
mes_author:
    .dc.b   'みゆ (miyu rose)',$0D,$0A,$0D,$0A,$00
mes_help:
    .dc.b   ' ROMDump.x ([options])',$0D,$0A
    .dc.b   '  [options]:',$0D,$0A
    .dc.b   '   f : $F00000-$FFFFFF   X68KROM.DAT をダンプします',$0D,$0A
    .dc.b   '   c : $F00000-$FBFFFF     CGROM.DAT をダンプします',$0D,$0A
    .dc.b   '   3 : $FC0000-$FDFFFF     ROM30.DAT が存在したらダンプします',$0D,$0A
    .dc.b   '   i : $FE0000-$FFFFFF    IPLROM.DAT をダンプします',$0D,$0A
    .dc.b   '   n : $FC0000-$FC1FFF SCSIINROM.DAT が存在したらダンプします',$0D,$0A
    .dc.b   '   x : $EA0020-$EA1FFF SCSIEXROM.DAT が存在したらダンプします',$0D,$0A
    .dc.b   '   a : 上記全てをダンプします',$0D,$0A
mes_crlf:
    .dc.b   $0D,$0A
mes_nul:
    .dc.b   $00

;===============================================================================

    .stack
    .even

;===============================================================================

mystack:
    .ds.l   1024
mysp:
    .end    main

;===============================================================================
