Copyright>        OpenRadioss
Copyright>        Copyright (C) 1986-2022 Altair Engineering Inc.
Copyright>    
Copyright>        This program is free software: you can redistribute it and/or modify
Copyright>        it under the terms of the GNU Affero General Public License as published by
Copyright>        the Free Software Foundation, either version 3 of the License, or
Copyright>        (at your option) any later version.
Copyright>    
Copyright>        This program is distributed in the hope that it will be useful,
Copyright>        but WITHOUT ANY WARRANTY; without even the implied warranty of
Copyright>        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Copyright>        GNU Affero General Public License for more details.
Copyright>    
Copyright>        You should have received a copy of the GNU Affero General Public License
Copyright>        along with this program.  If not, see <https://www.gnu.org/licenses/>.
Copyright>    
Copyright>    
Copyright>        Commercial Alternative: Altair Radioss Software 
Copyright>    
Copyright>        As an alternative to this open-source version, Altair also offers Altair Radioss 
Copyright>        software under a commercial license.  Contact Altair to discuss further if the 
Copyright>        commercial version may interest you: https://www.altair.com/radioss/.    
Chd|====================================================================
Chd|  H3D_SKIN_SCALAR               source/output/h3d/h3d_results/h3d_skin_scalar.F
Chd|-- called by -----------
Chd|        GENH3D                        source/output/h3d/h3d_results/genh3d.F
Chd|-- calls ---------------
Chd|        H3D_PRE_SKIN_SCALAR           source/output/h3d/h3d_results/h3d_skin_scalar.F
Chd|        H3D_SOL_SKIN_SCALAR           source/output/h3d/h3d_results/h3d_sol_skin_scalar.F
Chd|        INITBUF                       share/resol/initbuf.F         
Chd|        ELBUFDEF_MOD                  ../common_source/modules/elbufdef_mod.F
Chd|        H3D_MOD                       share/modules/h3d_mod.F       
Chd|        INITBUF_MOD                   share/resol/initbuf.F         
Chd|        MULTI_FVM_MOD                 ../common_source/modules/multi_fvm_mod.F
Chd|        SCHLIEREN_MOD                 share/modules/schlieren_mod.F 
Chd|====================================================================
      SUBROUTINE H3D_SKIN_SCALAR(
     .                  ELBUF_TAB       ,SKIN_SCALAR  ,IFUNC     ,IPARG       ,GEO         ,
     .                  IXS             ,IXS10 ,IXS16 , IXS20   ,PM          ,
     .                  IPM             ,IGEO         ,X            ,V         ,W          ,
     .                  IPARTS          ,H3D_PART    ,
     .                  IS_WRITTEN_SKIN ,INFO1        ,KEYWORD   , H3D_DATA  ,
     6                  IAD_ELEM        ,FR_ELEM     , WEIGHT    ,TAG_SKINS6,
     7                  NPF   ,TF    ,BUFMAT,IBCL    ,ILOADP     ,LLOADP    ,FAC    ,
     8                  SENSOR,LSENSOR ,TAGNCONT    ,LOADP_HYD_INTER,XFRAME,FORC    ,
     9                  NODAL_IPART ) 
C-----------------------------------------------
C   M o d u l e s
C-----------------------------------------------
      USE INITBUF_MOD
      USE ELBUFDEF_MOD    
      USE SCHLIEREN_MOD 
      USE H3D_MOD        
      USE MULTI_FVM_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
#include      "chara_c.inc"
#include      "nchara_c.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "vect01_c.inc"
#include      "mvsiz_p.inc"
#include      "com01_c.inc"
#include      "com04_c.inc"
#include      "scr01_c.inc"
#include      "scr03_c.inc"
#include      "scr05_c.inc"
#include      "scr14_c.inc"
#include      "scr25_c.inc"
#include      "param_c.inc"
#include      "rnur_c.inc"
#include      "task_c.inc"
#include      "spmd_c.inc"
#include      "mmale51_c.inc"
#include      "alefvm.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      my_real
     .   SKIN_SCALAR(*),X(3,*),V(3,*),W(3,*),GEO(NPROPG,*),PM(NPROPM,*),
     .   TF(*),BUFMAT(*)
      INTEGER IPARG(NPARG,*),IXS(NIXS,*),IFUNC,IXS10(*),IXS16(*), IXS20(*),
     .   IPM(NPROPMI,*),IGEO(NPROPGI,*),IPARTS(*),
     .   H3D_PART(*),IS_WRITTEN_SKIN(*),INFO1,
     .   IAD_ELEM(*),FR_ELEM(*), WEIGHT(*),TAG_SKINS6(*),NPF(*)
      INTEGER LLOADP(*),LSENSOR(NSENSI,*)
      INTEGER ILOADP(SIZLOADP,*),IBCL(NIBCLD,*),NODAL_IPART(*)
      INTEGER TAGNCONT(NLOADP_HYD_INTER,NUMNOD),LOADP_HYD_INTER(NLOADP_HYD)
      my_real
     .   FAC(LFACCLD,*), SENSOR(NSENSR,*), XFRAME(NXFRAME,*),FORC(*)
      TYPE (ELBUF_STRUCT_), DIMENSION(NGROUP), TARGET :: ELBUF_TAB
      CHARACTER*ncharline KEYWORD
      TYPE (H3D_DATABASE) :: H3D_DATA
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      my_real
     .   VALUE(MVSIZ),RINDX
      INTEGER I,I1,II,J,NG,NEL,NPTR,NPTS,NPTT,NLAY,L,IFAIL,ILAY,
     .        IR,IS,IT,IL,MLW, NUVAR,IUS,LENF,PTF,PTM,PTS,NFAIL,
     .        N,NN,K,K1,K2,JTURB,MT,IMID,IALEL,IPID,ISH3N,NNI,
     .        NN1,NN2,NN3,NN4,NN5,NN6,NN9,NF,BUF,NVARF,
     .        OFFSET,IHBE,NPTM,NPG, MPT,IPT,IADD,IADR,IPMAT,IFAILT,
     .        IIGEO,IADI,ISUBSTACK,ITHK,SWA_L,NB_PLYOFF,IUVAR,IDX,IPOS,ITRIMAT,
     .        IALEFVM_FLG, IMAT,IADBUF,NUPARAM,IOK_PART(MVSIZ)
      INTEGER 
     .        IS_WRITTEN_VALUE(MVSIZ),NFRAC,IU(4),IV,NB_FACE,KFACE,NSKIN
      TYPE(G_BUFEL_)  ,POINTER :: GBUF     
      TYPE(L_BUFEL_)  ,POINTER :: LBUF  
      TYPE(BUF_MAT_)  ,POINTER :: MBUF      
      TYPE(BUF_LAY_)  ,POINTER :: BUFLY     
      TYPE(BUF_FAIL_) ,POINTER :: FBUF 
C-----------------------------------------------
      NSKIN = 0
      IS_WRITTEN_SKIN(1:NUMSKIN) = 0
      IF (NUMSKIN> NUMSKINP) THEN      
      DO NG=1,NGROUP
C      
        CALL INITBUF (   IPARG   ,NG      ,                    
     2          MLW     ,NEL     ,NFT     ,IAD     ,ITY     ,  
     3          NPT     ,JALE    ,ISMSTR  ,JEUL    ,JTUR    ,  
     4          JTHE    ,JLAG    ,JMULT   ,JHBE    ,JIVF    ,  
     5          NVAUX   ,JPOR    ,JCVT    ,JCLOSE  ,JPLASOL ,  
     6          IREP    ,IINT    ,IGTYP   ,ISRAT   ,ISROT   ,  
     7          ICSEN   ,ISORTH  ,ISORTHG ,IFAILURE,JSMS    )
C     
       IF (MLW == 13 .OR. MLW == 0) CYCLE
C-----------------------------------------------
C       THICK-SHELL 
C-----------------------------------------------
!                8--------------7
!               / |            /|
!              5--------------|6
!              |  |           | |
!              |  4-----------|-3
!              | /            |/     
!              1--------------2
        IF (ITY == 1.AND.(IGTYP==20 .OR. IGTYP==21 .OR. IGTYP==22)) THEN
          NFT = IPARG(3,NG)
          LLT=NEL
          NLAY = ELBUF_TAB(NG)%NLAY                
          NPTR = ELBUF_TAB(NG)%NPTR                 
          NPTS = ELBUF_TAB(NG)%NPTS                 
          NPTT = ELBUF_TAB(NG)%NPTT
c
          DO I=1,NEL
            VALUE(I) = ZERO
            IS_WRITTEN_VALUE(I) = 0
            IOK_PART(I) = 0 
            IF( H3D_PART(IPARTS(NFT+I)) == 1) IOK_PART(I) = 1
          ENDDO	     
C-----------------------------------------------
          IF (KEYWORD == 'FLDZ/OUTER') THEN
            IS_WRITTEN_VALUE(1:NEL) = 1
C-----------------------------------------------
              ILAY=1
              IT = 1
C-------- grp skin_inf first
           IF (JHBE==15) THEN
              IR = 1
              IS = 1
              FBUF => ELBUF_TAB(NG)%BUFLY(ILAY)%FAIL(IR,IS,IT)                            
              NFAIL = ELBUF_TAB(NG)%BUFLY(ILAY)%NFAIL                                                                   
             DO IFAIL=1,NFAIL                                                          
               IF (FBUF%FLOC(IFAIL)%ILAWF == 7) THEN ! check /FLD model                
                  DO I=1,NEL 
                    RINDX = FBUF%FLOC(IFAIL)%INDX(I)                  
                    VALUE(I) = MAX(VALUE(I),RINDX) 
                    IS_WRITTEN_VALUE(I) = 1	                         
                  ENDDO                                                                 
               ENDIF
             END DO               
           ELSE ! 14,16
             DO IR=1,NPTR
               DO IS=1,NPTS
                  FBUF => ELBUF_TAB(NG)%BUFLY(ILAY)%FAIL(IR,IS,IT)                            
                  NFAIL = ELBUF_TAB(NG)%BUFLY(ILAY)%NFAIL                                                                   
                 DO IFAIL=1,NFAIL                                                          
                   IF (FBUF%FLOC(IFAIL)%ILAWF == 7) THEN ! check /FLD model                
                      DO I=1,NEL                                                      
                        RINDX = FBUF%FLOC(IFAIL)%INDX(I)                  
                        VALUE(I) = MAX(VALUE(I),RINDX) 
                      ENDDO                                                                 
                   ENDIF
                 END DO               
               ENDDO 
             ENDDO
C----------            
           END IF !IF (JHBE==15)             
C------           
           DO I=1,NEL
             SKIN_SCALAR(NSKIN+I) = VALUE(I)
             IF(IOK_PART(I) == 1 ) IS_WRITTEN_SKIN(NSKIN+I) = IS_WRITTEN_VALUE(I)
           END DO
           NSKIN = NSKIN + NEL
C-------- grp skin_up
              ILAY=NLAY
              IT = 1
              VALUE(1:NEL) = ZERO
           IF (JHBE==15) THEN
              IR = 1
              IS = 1
              FBUF => ELBUF_TAB(NG)%BUFLY(ILAY)%FAIL(IR,IS,IT)                            
              NFAIL = ELBUF_TAB(NG)%BUFLY(ILAY)%NFAIL                                                                   
             DO IFAIL=1,NFAIL                                                          
               IF (FBUF%FLOC(IFAIL)%ILAWF == 7) THEN ! check /FLD model                
                  DO I=1,NEL                                                      
                    RINDX = FBUF%FLOC(IFAIL)%INDX(I)                  
                    VALUE(I) = MAX(VALUE(I),RINDX) 
                    IS_WRITTEN_VALUE(I) = 1	                         
                  ENDDO                                                                 
               ENDIF
             END DO               
           ELSE ! 14,16
             DO IR=1,NPTR
               DO IS=1,NPTS
                  FBUF => ELBUF_TAB(NG)%BUFLY(ILAY)%FAIL(IR,IS,IT)                            
                  NFAIL = ELBUF_TAB(NG)%BUFLY(ILAY)%NFAIL                                                                   
                 DO IFAIL=1,NFAIL                                                          
                   IF (FBUF%FLOC(IFAIL)%ILAWF == 7) THEN ! check /FLD model                
                      DO I=1,NEL                                                      
                        RINDX = FBUF%FLOC(IFAIL)%INDX(I)                  
                        VALUE(I) = MAX(VALUE(I),RINDX) 
                        IS_WRITTEN_VALUE(I) = 1	                         
                      ENDDO                                                                 
                   ENDIF
                 END DO               
               ENDDO 
             ENDDO
           END IF   !IF (JHBE==15)            
           DO I=1,NEL
             SKIN_SCALAR(NSKIN+I) = VALUE(I)
             IF(IOK_PART(I) == 1 ) IS_WRITTEN_SKIN(NSKIN+I) = IS_WRITTEN_VALUE(I)
           END DO
           NSKIN = NSKIN + NEL
C-----------------------------------------------
          ELSEIF (KEYWORD == 'FLDF/OUTER') THEN
            IS_WRITTEN_VALUE(1:NEL) = 1
C-----------------------------------------------
              ILAY=1
              IT = 1
C-------- grp skin_inf first
           IF (JHBE==15) THEN
              IR = 1
              IS = 1
              FBUF => ELBUF_TAB(NG)%BUFLY(ILAY)%FAIL(IR,IS,IT)                            
              NFAIL = ELBUF_TAB(NG)%BUFLY(ILAY)%NFAIL                                                                   
             DO IFAIL=1,NFAIL                                                          
               IF (FBUF%FLOC(IFAIL)%ILAWF == 7) THEN ! check /FLD model                
                  DO I=1,NEL                                                      
                    VALUE(I) = MAX(VALUE(I),FBUF%FLOC(IFAIL)%DAM(I)) 
                    IS_WRITTEN_VALUE(I) = 1	                         
                  ENDDO                                                                 
               ENDIF
             END DO               
           ELSE ! 14,16
             DO IR=1,NPTR
               DO IS=1,NPTS
                  FBUF => ELBUF_TAB(NG)%BUFLY(ILAY)%FAIL(IR,IS,IT)                            
                  NFAIL = ELBUF_TAB(NG)%BUFLY(ILAY)%NFAIL                                                                   
                 DO IFAIL=1,NFAIL                                                          
                   IF (FBUF%FLOC(IFAIL)%ILAWF == 7) THEN ! check /FLD model                
                      DO I=1,NEL                                                      
                        VALUE(I) = MAX(VALUE(I),FBUF%FLOC(IFAIL)%DAM(I)) 
                        IS_WRITTEN_VALUE(I) = 1	                         
                      ENDDO                                                                 
                   ENDIF
                 END DO               
               ENDDO 
             ENDDO
C----------            
           END IF !IF (JHBE==15)             
C------           
           DO I=1,NEL
             N = I + NFT
             SKIN_SCALAR(NSKIN+I) = VALUE(I)
             IF(IOK_PART(I) == 1 ) IS_WRITTEN_SKIN(NSKIN+I) = IS_WRITTEN_VALUE(I)
           END DO
           NSKIN = NSKIN + NEL
C-------- grp skin_up
              ILAY=NLAY
              IT = 1
           VALUE(1:NEL) = ZERO
           IF (JHBE==15) THEN
              IR = 1
              IS = 1
              FBUF => ELBUF_TAB(NG)%BUFLY(ILAY)%FAIL(IR,IS,IT)                            
              NFAIL = ELBUF_TAB(NG)%BUFLY(ILAY)%NFAIL                                                                   
             DO IFAIL=1,NFAIL                                                          
               IF (FBUF%FLOC(IFAIL)%ILAWF == 7) THEN ! check /FLD model                
                  DO I=1,NEL                                                      
                    VALUE(I) = MAX(VALUE(I),FBUF%FLOC(IFAIL)%DAM(I)) 
                    IS_WRITTEN_VALUE(I) = 1	                         
                  ENDDO                                                                 
               ENDIF
             END DO               
           ELSE ! 14,16
             DO IR=1,NPTR
               DO IS=1,NPTS
                  FBUF => ELBUF_TAB(NG)%BUFLY(ILAY)%FAIL(IR,IS,IT)                            
                  NFAIL = ELBUF_TAB(NG)%BUFLY(ILAY)%NFAIL                                                                   
                 DO IFAIL=1,NFAIL                                                          
                   IF (FBUF%FLOC(IFAIL)%ILAWF == 7) THEN ! check /FLD model                
                      DO I=1,NEL                                                      
                        VALUE(I) = MAX(VALUE(I),FBUF%FLOC(IFAIL)%DAM(I)) 
                        IS_WRITTEN_VALUE(I) = 1	                         
                      ENDDO                                                                 
                   ENDIF
                 END DO               
               ENDDO 
             ENDDO
           END IF   !IF (JHBE==15)            
           DO I=1,NEL
             N = I + NFT
             SKIN_SCALAR(NSKIN+I) = VALUE(I)
             IF(IOK_PART(I) == 1 ) IS_WRITTEN_SKIN(NSKIN+I) = IS_WRITTEN_VALUE(I)
           END DO
           NSKIN = NSKIN + NEL
C------------to get right NSKIN for next case          
          ELSE
           NSKIN = NSKIN + 2*NEL
          END IF !(KEYWORD
        END IF !(ITY == 1.AND.(IGTYP==20 .OR. IGTYP==21 .OR. IGTYP==22)) THEN
      END DO !NG=1,NGROUP
      END IF !(NUMSKIN> NUMSKINP) THEN      
C------for solid elements
       IF (NUMSKIN> (NSKIN+NUMSKINP))       
     .  CALL H3D_SOL_SKIN_SCALAR(
     .                   ELBUF_TAB,SKIN_SCALAR, IPARG   ,IXS     ,X     ,PM  ,
     4                   IPARTS  ,IPM     ,IGEO    ,IXS10 ,IXS16 , IXS20  ,
     5                   IS_WRITTEN_SKIN  ,H3D_PART,INFO1   ,KEYWORD ,NSKIN ,
     6                   IAD_ELEM        ,FR_ELEM     , WEIGHT   ,TAG_SKINS6,
     7                   NPF  ,TF   ,BUFMAT)
C------for solid elements
       IF (NUMSKINP> 0)       
     .  CALL H3D_PRE_SKIN_SCALAR(SKIN_SCALAR,NODAL_IPART,
     .                   IS_WRITTEN_SKIN  ,H3D_PART,INFO1   ,KEYWORD ,
     .                   IBCL,ILOADP,LLOADP,FAC ,NPF,TF ,SENSOR,LSENSOR ,
     .                   TAGNCONT,LOADP_HYD_INTER,FORC,XFRAME ,X ,V ,NSKIN )
C-----------------------------------------------
      RETURN
      END
Chd|====================================================================
Chd|  H3D_PRE_SKIN_SCALAR           source/output/h3d/h3d_results/h3d_skin_scalar.F
Chd|-- called by -----------
Chd|        H3D_SKIN_SCALAR               source/output/h3d/h3d_results/h3d_skin_scalar.F
Chd|-- calls ---------------
Chd|        FINTER                        source/tools/curve/finter.F   
Chd|        FINTER_SMOOTH                 source/tools/curve/finter_smooth.F
Chd|        GET_U_SENS_VALUE              source/user_interface/usensor.F
Chd|        SET_U_SENS_VALUE              source/user_interface/usensor.F
Chd|        H3D_MOD                       share/modules/h3d_mod.F       
Chd|        PBLAST_MOD                    ../common_source/modules/pblast_mod.F
Chd|        PINCHTYPE_MOD                 ../common_source/modules/pinchtype_mod.F
Chd|====================================================================
      SUBROUTINE H3D_PRE_SKIN_SCALAR(SKIN_SCALAR,NODAL_IPART,
     .                   IS_WRITTEN_SKIN  ,H3D_PART,INFO1   ,KEYWORD ,
     .                   IB ,ILOADP,LLOADP,FAC ,NPC,TF ,SENSOR,LSENSOR ,
     .                   TAGNCONT,LOADP_HYD_INTER,FORC,XFRAME,X ,V ,NSKIN )
C-----------------------------------------------
C   M o d u l e s 
C-----------------------------------------------
      USE H3D_MOD
      USE PINCHTYPE_MOD 
      USE PBLAST_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
#include      "param_c.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "com01_c.inc"
#include      "com04_c.inc"
#include      "com06_c.inc"
#include      "com08_c.inc"
#include      "tabsiz_c.inc"
C-----------------------------------------------
C   E x t e r n a l  F u n c t i o n s
C-----------------------------------------------
C-----------------------------------------------
C   E x t e r n a l  F u n c t i o n s
C-----------------------------------------------
      INTEGER  GET_U_NUMSENS,GET_U_SENS_FPAR,GET_U_SENS_IPAR,
     .         GET_U_SENS_VALUE,SET_U_SENS_VALUE
      EXTERNAL GET_U_NUMSENS,GET_U_SENS_FPAR,GET_U_SENS_IPAR,
     .         GET_U_SENS_VALUE,SET_U_SENS_VALUE
C-----------------------------------------------,
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      my_real
     .   SKIN_SCALAR(*),TF(*),X(3,*),V(3,*)
      CHARACTER*ncharline KEYWORD
      TYPE (H3D_DATABASE) :: H3D_DATA
      INTEGER
     .   H3D_PART(*),IS_WRITTEN_SKIN(*),INFO1,NPC(*)
      INTEGER LLOADP(SLLOADP),NSKIN,LSENSOR(NSENSI,*)
      INTEGER ILOADP(SIZLOADP,*),IB(NIBCLD,*)
      INTEGER TAGNCONT(NLOADP_HYD_INTER,NUMNOD),
     .        LOADP_HYD_INTER(NLOADP_HYD),NODAL_IPART(*)
      my_real
     .   FAC(LFACCLD,*), SENSOR(NSENSR,*), XFRAME(NXFRAME,*),FORC(LFACCLD,*)
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER NL, N1, ISK, N2, N3, N4, N5, 
     .        IAD ,NP ,IFUNC ,NPRES,NSKIN0,NSKIN1,N1FRAM,DIR_HSP,I,N
      INTEGER K1, K2, K3, ISENS,K,LL,IERR,
     .        N_OLD, ISMOOTH,IDEL,NINTERP ,NPL,TAGN1,TAGN2,TAGN3,TAGN4,
     .        FUN_CX,FUN_VEL,DIR_VEL,IFRA2, IANIM,IJK,UP_BOUND,
     .        IZ_UPDATE,ABAC_ID,ISIZ_SEG,IERR1,
     .        Phi_I, ID, USER_ID, ITA_SHIFT,NDT,NDT0,
     .        NITER,ITER,IMODEL,IL,IS,SEGCONT,FUN_HSP,IFRA1,IFLOAD
      my_real
     .   NX, NY, NZ, AXI, AA, A0, VV, FX, FY, FZ, AX, DYDX, TS,
     .   SIXTH,TFEXTT,X_OLD, F1, F2,XSENS,FCX,FCY,FCYPINCH,FP,
     .   FCX1,FCY1,FCX2,FCY2,VX,VY,VZ,VEL,VSEG,NORM
      my_real FINTER, ZFx,ZFy,ZFz, ZZFx,ZZFy,ZZFz,PS, Zx,Zy,Zz,FINTER_SMOOTH
      my_real
     .   LAMBDA,VSEGX, VSEGY, VSEGZ,
     .   cos_theta, alpha_inci, alpha_refl, P_inci, P_refl_,P_inci_, P_refl,Z, 
     .   I_inci,I_refl,I_inci_,I_refl_, dt_0, t_a,dt_0_,
     .   WAVE_refl,WAVE_inci, W13, P0, T_,Phi_DB,bound1,bound2
      my_real COORMEAN,YMEAN,ZMEAN,PVEL,NSIGN,DNORM,
     .        Xdet,Ydet,Zdet,Tdet,Wtnt,PMIN,Dx,Dy,Dz,NORMD, P,
     .        FAC_M_bb, FAC_L_bb, FAC_T_bb, FAC_P_bb, FAC_I_bb, T0INF_LOC, TA_SHIFT, TT_STAR
      
      DOUBLE PRECISION A_,B_,Z0_
      
      my_real DECAY_inci,DECAY_refl,ZETA,ZETA2,ZETA3,TMP,TMP2,TMP3,TMP4,FUNCT,DIFF,RES,TOL,T_INF,T_FIN,T_ZERO
      my_real H00,H10,H01,H11,pP0,pP1,pM0,pM1,kk,m2,PI_,Ic,alpha,diff_t0_inci,diff_t0_refl
      
      DATA PI_/3.141592653589793238462643D0/
      EXTERNAL FINTER,FINTER_SMOOTH
C=======================================================================
C---- fill SKIN_SCALAR(*) w/ IS_WRITTEN_SKIN(*)=1
        IF (KEYWORD /= 'PEXT') RETURN
C-----Force (pressure) first 
      N_OLD  = 0
      X_OLD  = ZERO
       DO NL=1,NCONLD-NPLOADPINCH
         N1      = IB(1,NL)
         N2      = IB(2,NL)
         N3      = IB(3,NL)
         N4      = IB(4,NL)
         N5      = IB(5,NL)
         IDEL    = IB(8,NL)
         FCY     = FORC(1,NL)
         FCX     = FORC(2,NL)
		 IF (N1==0.OR.N2==0.OR.N3==0.OR.N4==-1) CYCLE
C--------default zero        
		 NSKIN = NSKIN + 1
		 SKIN_SCALAR(NSKIN)=ZERO
         IF (NODAL_IPART(N1)>0) THEN
		   IF (H3D_PART(NODAL_IPART(N1))==1) IS_WRITTEN_SKIN(NSKIN)=1
         END IF
         ISENS   = 0
         XSENS   = ONE
         DO K=1,NSENSOR
           IF(IB(6,NL).EQ.LSENSOR(1,K))ISENS=K
         ENDDO
         IF(ISENS.EQ.0)THEN
            TS=TT
         ELSEIF (LSENSOR(4,ISENS)==753096514 .AND. TT /= ZERO) THEN
           IERR = SET_U_SENS_VALUE(ISENS,1,ZERO)
           IERR = GET_U_SENS_VALUE(ISENS,2,XSENS)
         ELSE
            TS = TT-SENSOR(2,ISENS)
            IF(TS < ZERO) CYCLE
         ENDIF
         IF(IDEL > 0 ) CYCLE  ! SEGMENT DELETED
         IF(N_OLD.NE.N5.OR.X_OLD.NE.TS) THEN
           ISMOOTH = 0
           IF (N5 > 0) ISMOOTH = NPC(2*NFUNCT+N5+1)
!!           F1 = FINTER(N5,TS*FCX,NPC,TF,DYDX)
           IF (ISMOOTH == 0) THEN
             F1 = FINTER(N5,TS*FCX,NPC,TF,DYDX)
           ELSE
             F1 = FINTER_SMOOTH(N5,TS*FCX,NPC,TF,DYDX)
           ENDIF ! IF (ISMOOTH == 0)
           N_OLD = N5
           X_OLD = TS
         ENDIF
         AA = FCY*F1*XSENS
		 SKIN_SCALAR(NSKIN)=AA
       END DO 
C----------load_pressure	
       DO NP=1,NLOADP_HYD
         ISIZ_SEG = ILOADP(1,NP)/4 
         IFUNC = ILOADP(3,NP)
         IAD = ILOADP(4,NP)
         NINTERP = ILOADP(5,NP)
         ISENS =  ILOADP(7,NP) 
         IFLOAD =  ILOADP(10,NP) 
         FCY = FAC(1,NP)
         FCX = FAC(2,NP)
C--------default zero        
         DO N=1, ISIZ_SEG
           N1 = LLOADP(IAD+4*(N-1))
           N2 = LLOADP(IAD+4*(N-1)+1)
           N3 = LLOADP(IAD+4*(N-1)+2)
           N4 = LLOADP(IAD+4*(N-1)+3)
           IF (N1==0.OR.N2==0.OR.N3==0) CYCLE
           SKIN_SCALAR(NSKIN+N)=ZERO
           IF (NODAL_IPART(N1)>0) THEN
              IF (H3D_PART(NODAL_IPART(N1))==1) IS_WRITTEN_SKIN(NSKIN+N)=1
           END IF
         ENDDO
C
         IF(ISENS.EQ.0)THEN
            TS=TT
         ELSE
            TS = TT-SENSOR(2,ISENS)
            IF(TS.LT.ZERO) CYCLE
         ENDIF    
         DO N=1, ISIZ_SEG
           N1 = LLOADP(IAD+4*(N-1))
           N2 = LLOADP(IAD+4*(N-1)+1)
           N3 = LLOADP(IAD+4*(N-1)+2)
           N4 = LLOADP(IAD+4*(N-1)+3)
		   IF (N1==0.OR.N2==0.OR.N3==0) CYCLE

           F1 = FINTER(IFUNC,TS*FCX,NPC,TF,DYDX)
           AA = FCY*F1  
C----------------
C       Check if segment is in contact 
C----------------
             SEGCONT = 0

             TAGN1 = 0
             TAGN2 = 0
             TAGN3 = 0
             TAGN4 = 0
             FP = ONE
             IF(NINTERP > 0 ) THEN           
                NPL = LOADP_HYD_INTER(NP)
                IF(N4/=0) THEN
                   SEGCONT = TAGNCONT(NPL,N1) + TAGNCONT(NPL,N2) +
     .                     TAGNCONT(NPL,N3)+TAGNCONT(NPL,N4)
                   IF(SEGCONT >= 2 .AND.IFLOAD==1) THEN
                      SEGCONT = 1
                   ELSEIF(SEGCONT <= 1.AND.IFLOAD==2) THEN
                      SEGCONT = 1
                   ELSE
                      SEGCONT = 0
                   ENDIF
                ELSE
                   SEGCONT = TAGNCONT(NPL,N1) + TAGNCONT(NPL,N2) +
     .                     TAGNCONT(NPL,N3)
                   IF(SEGCONT >= 2 .AND.IFLOAD==1) THEN
                      SEGCONT = 1
                   ELSEIF(SEGCONT <= 1.AND.IFLOAD==2) THEN
                      SEGCONT = 1
                   ELSE
                      SEGCONT = 0
                   ENDIF
                ENDIF    
c                IF (FP==ZERO) FP = ONE
             ENDIF
             IF (SEGCONT==1) AA = ZERO
             NSKIN = NSKIN +1
             SKIN_SCALAR(NSKIN)=AA*FP
         END DO !N=1, NPRES/4
       END DO !NP=1,NLOADP_HYD
C---------pfluid	   
       DO NL=1,NLOADP_F
C--------default zero        
         ISIZ_SEG = ILOADP(1,NP)/4 
         IAD = ILOADP(4,NP)
         DO N=1, ISIZ_SEG
           N1 = LLOADP(IAD+4*(N-1))
           N2 = LLOADP(IAD+4*(N-1)+1)
           N3 = LLOADP(IAD+4*(N-1)+2)
           N4 = LLOADP(IAD+4*(N-1)+3)
		   IF (N1==0.OR.N2==0.OR.N3==0) CYCLE
		   SKIN_SCALAR(NSKIN+N)=ZERO
           IF (NODAL_IPART(N1)>0) THEN
		     IF (H3D_PART(NODAL_IPART(N1))==1) IS_WRITTEN_SKIN(NSKIN+N)=1
           END IF
         ENDDO
         FUN_HSP=ILOADP(7,NL)
         DIR_HSP=ILOADP(8,NL)
         IFRA1=ILOADP(9,NL)
         FCY = FAC(1,NL)
         FCX = FAC(2,NL)
         FUN_CX=ILOADP(10,NL)
         FCY1 = FAC(3,NL)
         FCX1 = FAC(4,NL)
         FUN_VEL=ILOADP(11,NL)
         FCY2 = FAC(5,NL)
         FCX2 = FAC(6,NL)
         ! To avoid a check bound issue when the velocity options are not set in the input, 
         ! the DIR_VEL variable is bounded to a minimal value of 1
         DIR_VEL=MAX(ILOADP(12,NL),1)
         IFRA2=ILOADP(13,NL)
         ISENS=0
         XSENS = ONE
         DO K=1,NSENSOR
           IF(ILOADP(6,NL).EQ.LSENSOR(1,K))ISENS=K
         ENDDO
         IF(ISENS.EQ.0)THEN
            TS=TT
         ELSEIF (LSENSOR(4,ISENS)==753096514 .AND. TT /= ZERO) THEN
           IERR = SET_U_SENS_VALUE(ISENS,1,ZERO)         
           IERR = GET_U_SENS_VALUE(ISENS,2,XSENS)  
         ELSE                        
            TS = TT-SENSOR(2,ISENS)  
            IF(TS < ZERO) CYCLE     
         ENDIF
         DO I = 1,ISIZ_SEG
           N1=LLOADP(ILOADP(4,NL)+4*(I-1))
           N2=LLOADP(ILOADP(4,NL)+4*(I-1)+1)
           N3=LLOADP(ILOADP(4,NL)+4*(I-1)+2)
           N4=LLOADP(ILOADP(4,NL)+4*(I-1)+3)
		   IF (N1==0.OR.N2==0.OR.N3==0) CYCLE
C        
           AA = ZERO
           VEL = ZERO
           PVEL=ZERO
C------  ----------  
C        
           IF(N4.NE.0 .AND. N1.NE.N2 .AND. N1.NE.N3 .AND. N1.NE.N4 .AND.
     .                      N2.NE.N3 .AND. N2.NE.N4 .AND. N3.NE.N4 )THEN
C        
             K1=3*DIR_HSP-2
             K2=3*DIR_HSP-1
             K3=3*DIR_HSP
             ! hydrostatic pressure
             IF(FUN_HSP .NE.0)THEN
                COORMEAN = (XFRAME(K1,IFRA1)*(X(1,N1)+X(1,N2)+X(1,N3)+X(1,N4))/FOUR)+
     .                     (XFRAME(K2,IFRA1)*(X(2,N1)+X(2,N2)+X(2,N3)+X(2,N4))/FOUR)+
     .                     (XFRAME(K3,IFRA1)*(X(3,N1)+X(3,N2)+X(3,N3)+X(3,N4))/FOUR)
                AA       = FCY*FINTER(FUN_HSP,(COORMEAN-XFRAME(9+DIR_HSP,IFRA1))*FCX,NPC,TF,DYDX)
             ENDIF
             NX= (X(2,N3)-X(2,N1))*(X(3,N4)-X(3,N2)) - (X(3,N3)-X(3,N1))*(X(2,N4)-X(2,N2))
             NY= (X(3,N3)-X(3,N1))*(X(1,N4)-X(1,N2)) - (X(1,N3)-X(1,N1))*(X(3,N4)-X(3,N2))
             NZ= (X(1,N3)-X(1,N1))*(X(2,N4)-X(2,N2)) - (X(2,N3)-X(2,N1))*(X(1,N4)-X(1,N2))
             NORM = SQRT(NX*NX+NY*NY+NZ*NZ)
             AA = AA * HALF * NORM
C vel pressure
             K1=3*DIR_VEL-2
             K2=3*DIR_VEL-1
             K3=3*DIR_VEL
c         
             NSIGN = (NX * XFRAME(K1,IFRA2) + 
     .                NY * XFRAME(K2,IFRA2) + 
     .                NZ * XFRAME(K3,IFRA2)) 
             IF(NSIGN.NE.ZERO) NSIGN = SIGN(ONE,NSIGN)
C         
             VSEG= (XFRAME(K1,IFRA2)*
     .               (V(1,N1) + V(1,N2) + V(1,N3) + V(1,N4)) /FOUR)+
     .              (XFRAME(K2,IFRA2)*
     .               (V(2,N1) + V(2,N2) + V(2,N3) + V(2,N4)) /FOUR)+
     .              (XFRAME(K3,IFRA2)*
     .               (V(3,N1) + V(3,N2) + V(3,N3) + V(3,N4)) /FOUR)
             
             IF(FUN_VEL .NE.0)THEN
                VEL =  FCY2*FINTER(FUN_VEL,TT*FCX2,NPC,TF,DYDX)- VSEG
             ELSE
                VEL =  - VSEG
             ENDIF
             IF(FUN_CX .NE.0)   
     .         PVEL = (  (-(NX/NORM)*VEL*XFRAME(K1,IFRA2)-
     .                 (NY/NORM)*VEL*XFRAME(K2,IFRA2)-
     .                 (NZ/NORM)*VEL*XFRAME(K3,IFRA2))**2  )* FCY1*
     .              FINTER(FUN_CX,TT*FCX1,NPC,TF,DYDX)/TWO
C         
           ELSE
            IF(N1 == N2)THEN
              N2 = N3
              N3 = N4
              N4 = 0
            ELSEIF(N1 == N3)THEN
              N3 = N4
              N4 = 0
            ELSEIF(N1 == N4)THEN
              N4 = 0
            ELSEIF(N2 == N3)THEN
              N3 = N4
              N4 = 0
            ELSEIF(N2 == N4)THEN
              N2 = N3
              N3 = N4
              N4 = 0
            ELSEIF(N3 == N4)THEN
              N4 = 0
            ENDIF
Csv         true triangles.
            IF(FUN_HSP .NE.0)THEN
               K1=3*DIR_HSP-2
               K2=3*DIR_HSP-1
               K3=3*DIR_HSP
               ! hydrostatic pressure
               COORMEAN = (XFRAME(K1,IFRA1)*(X(1,N1)+X(1,N2)+X(1,N3))/THREE)+
     .                    (XFRAME(K2,IFRA1)*(X(2,N1)+X(2,N2)+X(2,N3))/THREE)+
     .                    (XFRAME(K3,IFRA1)*(X(3,N1)+X(3,N2)+X(3,N3))/THREE)
               AA       =  FCY*FINTER(FUN_HSP,(COORMEAN-XFRAME(9+DIR_HSP,IFRA1))*FCX,NPC,TF,DYDX)
            ENDIF
            NX= (X(2,N3)-X(2,N1))*(X(3,N4)-X(3,N2)) - (X(3,N3)-X(3,N1))*(X(2,N4)-X(2,N2))
            NY= (X(3,N3)-X(3,N1))*(X(1,N4)-X(1,N2)) - (X(1,N3)-X(1,N1))*(X(3,N4)-X(3,N2))
            NZ= (X(1,N3)-X(1,N1))*(X(2,N4)-X(2,N2)) - (X(2,N3)-X(2,N1))*(X(1,N4)-X(1,N2))
            NORM = SQRT(NX*NX+NY*NY+NZ*NZ)
            AA = AA * HALF * NORM
C vel pressure
             K1=3*DIR_VEL-2
             K2=3*DIR_VEL-1
             K3=3*DIR_VEL
c           
             NSIGN = (NX * XFRAME(K1,IFRA2) + 
     .                NY * XFRAME(K2,IFRA2) + 
     .                NZ * XFRAME(K3,IFRA2)) 
             IF(NSIGN.NE.ZERO) NSIGN = SIGN(ONE,NSIGN)
C           
             VSEG= (XFRAME(K1,IFRA2)*
     .               (V(1,N1) + V(1,N2) + V(1,N3)) /THREE)+
     .              (XFRAME(K2,IFRA2)*
     .               (V(2,N1) + V(2,N2) + V(2,N3)) /THREE)+
     .              (XFRAME(K3,IFRA2)*
     .               (V(3,N1) + V(3,N2) + V(3,N3)) /THREE)
             
             IF(FUN_VEL .NE.0)THEN
                VEL =  FCY2*FINTER(FUN_VEL,TT*FCX2,NPC,TF,DYDX)- VSEG
             ELSE
                VEL =  - VSEG
             ENDIF
             IF(FUN_CX .NE.0)   
     .         PVEL = (  (-(NX/NORM)*VEL*XFRAME(K1,IFRA2)-
     .                 (NY/NORM)*VEL*XFRAME(K2,IFRA2)-
     .                 (NZ/NORM)*VEL*XFRAME(K3,IFRA2))**2  )* FCY1*
     .              FINTER(FUN_CX,TT*FCX1,NPC,TF,DYDX)/TWO
           ENDIF
		  	NSKIN = NSKIN +1
		    SKIN_SCALAR(NSKIN)=-AA+PVEL*NSIGN
         END DO 
       END DO 
C---------pblast	   
       DO NL=1+NLOADP_F,NLOADP_F+NLOADP_B
C--------default zero        
         ISIZ_SEG  = ILOADP(1,NL)/4 
         IAD = ILOADP(4,NL)
         DO N=1, ISIZ_SEG
           N1 = LLOADP(IAD+4*(N-1))
           N2 = LLOADP(IAD+4*(N-1)+1)
           N3 = LLOADP(IAD+4*(N-1)+2)
           N4 = LLOADP(IAD+4*(N-1)+3)
		   IF (N1==0.OR.N2==0.OR.N3==0) CYCLE
		   SKIN_SCALAR(NSKIN+N)=ZERO
           IF (NODAL_IPART(N1)>0) THEN
		     IF (H3D_PART(NODAL_IPART(N1))==1) IS_WRITTEN_SKIN(NSKIN+N)=1
           END IF
         ENDDO
         IL             = NL-NLOADP_F
         TDET           = FAC(01,NL)
         ID             = ILOADP(08,NL) !user_id
         IF(TT<TDET)CYCLE
         !---------------------------------------------
         !   LOOP ON SEGMENTS (4N or 3N)
         !---------------------------------------------      
         DO I = 1,ISIZ_SEG
           N1=LLOADP(ILOADP(4,NL)+4*(I-1))
           N2=LLOADP(ILOADP(4,NL)+4*(I-1)+1)
           N3=LLOADP(ILOADP(4,NL)+4*(I-1)+2)
           N4=LLOADP(ILOADP(4,NL)+4*(I-1)+3) 
		   IF (N1==0.OR.N2==0.OR.N3==0) CYCLE           
           !Dist                                                                                                          
           
           P = PBLAST_TAB(IL)%PRES(I)                                                           
		   NSKIN = NSKIN +1
		   SKIN_SCALAR(NSKIN)= -P
         ENDDO!next I
       END DO 
C
      RETURN
      END
