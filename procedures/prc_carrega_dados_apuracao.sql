CREATE OR REPLACE FUNCTION public.prc_carrega_dados_apuracao (
  p_apuracao bigint
)
RETURNS varchar AS
$body$
declare

x              RECORD;
y              RECORD;
z              RECORD;

v_retorno      VARCHAR(200);
v_linha        TEXT;
v_coluna       TEXT[];
v_data_in      DATE;
v_data_fi      DATE;

v_contador     INTEGER;
v_existe       INTEGER;
v_seq          INTEGER;
--v_itseq        INTEGER;
v_cup          INTEGER;
v_itcup        INTEGER;
v_eng          INTEGER;
v_fre          INTEGER;
v_itfre        INTEGER;

v_total        NUMERIC;

v_ecf_cx       VARCHAR(3);

v_participante VARCHAR(60);
v_produto      VARCHAR(60);

BEGIN
  v_retorno  := 'OK';
  v_contador := 1; 
  for x in (select string_to_array(encode(carqtxtapura,'escape'),chr(10)) as registro,
                   string_to_array(encode(carqentapura,'escape'),chr(10)) as regent, 
                   string_to_array(encode(carqsaiapura,'escape'),chr(10)) as regsai, 
                   b.ncnpjcontr
              from audapura a, audcontr b
             where a.nnumeroapura = p_apuracao
               and b.nnumerocontr = a.nnumerocontr)
  loop
  
    v_linha  := x.registro[v_contador];

    v_seq := 0;
    v_cup := 0;
    v_eng := 0;
    v_fre := 0;
    
    v_ecf_cx := '';
    
    while (v_retorno = 'OK') and (substr(v_linha,1,5) <> '|9999')
    loop
      ------------------------------------------------------------------------
      --REGISTRO 0000: ABERTURA DO ARQUIVO DIGITAL E IDENTIFICAÇÃO DA ENTIDADE
      ------------------------------------------------------------------------
      if substr(v_linha,1,5) = '|0000' then

         v_coluna := string_to_array(v_linha,'|');
           
         -- trava do CNPJ
         if v_coluna[8] <> x.ncnpjcontr then
            v_retorno := 'CNPJ do arquivo nao confere com o do cliente.verificar! CNPJ ARQUIVO : '||v_coluna[7];
            exit;
         end if;

         -- Perfil do Informante:
         -- “A” determina a apresentação dos registros mais detalhados
         -- “B” trata as informações de forma sintética
         if v_coluna[15] <> 'A' then
            v_retorno := 'Perfil do informante invalido. O perfil deve ser = "A" (registros detalhados). Verifique.';
            exit;
         end if;
       
         v_data_in := cast(substr(v_coluna[5],1,2)||'/'||substr(v_coluna[5],3,2)||'/'||substr(v_coluna[5],5,4) as DATE);
         v_data_fi := cast(substr(v_coluna[6],1,2)||'/'||substr(v_coluna[6],3,2)||'/'||substr(v_coluna[6],5,4) as DATE);

         update audapura
            set ddatiniapura = v_data_in,
                ddatfimapura = v_data_fi
          where nnumeroapura = p_apuracao;
      end if;

      ---------------------------------------------------
      --REGISTRO 0150: TABELA DE CADASTRO DO PARTICIPANTE
      ---------------------------------------------------
      if substr(v_linha,1,5) = '|0150' then
         v_coluna := string_to_array(v_linha,'|');      
         insert into audparti (nnumeroapura,
                               ccodigoparti,
                               cdescriparti,
                               ncodpaiparti,
                               ncnpj__parti,
                               ncpf___parti,
                               cie____parti,
                               ncodmunparti,
                               csuframparti,
                               cendereparti,
                               cnumendparti,
                               ccompleparti,
                               cbairroparti)
                       values (p_apuracao,
                               v_coluna[3],
                               v_coluna[4],
                               v_coluna[5],
                               v_coluna[6],
                               v_coluna[7],
                               v_coluna[8],
                               v_coluna[9],
                               v_coluna[10],
                               v_coluna[11],
                               v_coluna[12],
                               v_coluna[13],
                               v_coluna[14]);
      end if;

      ---------------------------------------------------------------------
      --REGISTRO 0200: TABELA DE IDENTIFICAÇÃO DO ITEM (PRODUTO E SERVIÇOS)
      ---------------------------------------------------------------------
      if substr(v_linha,1,5) = '|0200' then
      
         v_coluna := string_to_array(v_linha,'|');
      
         -- verifica e importa o NCM para a tabela caso não exista:
         perform prc_importar_ncm_planilha(v_coluna[9],v_coluna[4]);
      
         insert into audprodu (nnumeroapura,
                               ccodigoprodu,
                               cdescriprodu,
                               ccodbarprodu,
                               ccodantprodu,
                               cundinvprodu,
                               ctipiteprodu,
                               ccodncmprodu,
                               cex_ipiprodu,
                               ccodgenprodu,
                               ccodlstprodu,
                               nalqicmprodu)
                       values (p_apuracao,
                               v_coluna[3],
                               UPPER(v_coluna[4]),
                               v_coluna[5],
                               v_coluna[6],
                               v_coluna[7],
                               v_coluna[8],
                               v_coluna[9],
                               v_coluna[10],
                               v_coluna[11],
                               v_coluna[12],
                               prc_StrToFloatDef(v_coluna[13]) );
      end if;

      ----------------------------
      --REGISTRO C100: NOTA FISCAL
      ----------------------------
      if substr(v_linha,1,5) = '|C100' then
         v_coluna := string_to_array(v_linha,'|');
         -- quando a situacao é 02 (CANCELADO) nao precisa importar (JOAO em 14/04/2014) 
         if v_coluna[7] <> '02' then
            if (v_coluna[5] = '') or (v_coluna[5] = ' ') or (v_coluna[5] is null) then
               v_linha := cast(v_contador as varchar)||'='||substr(v_linha,1,50);
               v_retorno := 'Codigo do Participante em branco. Verifique. Linha: '||substr(v_linha,1,50);
               exit;
            end if;
            v_seq := v_seq + 1;
            insert into auddocto (nnumeroapura,
                                  nsequendocto,
                                  ctipoesdocto,
                                  cindemidocto,
                                  ccodigoparti,
                                  cmodelodocto,
                                  ccodsitdocto,
                                  ccodserdocto,
                                  nnumerodocto,
                                  nchvnfedocto,
                                  ddatemidocto,
                                  ddate_sdocto,
                                  nvlrtotdocto,
                                  nvlrdesdocto,
                                  nvlabntdocto,
                                  nvlmesedocto,
                                  nindfredocto,
                                  nvlrfredocto,
                                  nvlrsegdocto,
                                  nvloudadocto,
                                  nvlbcicdocto,
                                  nvlricmdocto,
                                  nbcicstdocto,
                                  nvlicstdocto,
                                  nvlripidocto,
                                  nvlrpisdocto,
                                  nvlrcofdocto,
                                  nvlpistdocto,
                                  nvlcostdocto,
                                  nindpagdocto)
                          values (p_apuracao,
                                  v_seq,
                                  v_coluna[3],
                                  v_coluna[4],                               
                                  v_coluna[5],
                                  v_coluna[6],
                                  v_coluna[7],
                                  v_coluna[8],
                                  v_coluna[9],
                                  v_coluna[10],
                                  v_coluna[11],
                                  v_coluna[12],
                                  prc_StrToFloatDef(v_coluna[13]),
                                  prc_StrToFloatDef(v_coluna[15]),
                                  prc_StrToFloatDef(v_coluna[16]),
                                  prc_StrToFloatDef(v_coluna[17]),
                                  v_coluna[18],
                                  prc_StrToFloatDef(v_coluna[19]),
                                  prc_StrToFloatDef(v_coluna[20]),
                                  prc_StrToFloatDef(v_coluna[21]),
                                  prc_StrToFloatDef(v_coluna[22]),
                                  prc_StrToFloatDef(v_coluna[23]),
                                  prc_StrToFloatDef(v_coluna[24]),
                                  prc_StrToFloatDef(v_coluna[25]),
                                  prc_StrToFloatDef(v_coluna[26]),
                                  prc_StrToFloatDef(v_coluna[27]),
                                  prc_StrToFloatDef(v_coluna[28]),
                                  prc_StrToFloatDef(v_coluna[29]),
                                  prc_StrToFloatDef(v_coluna[29]),
                                  v_coluna[14]);
         end if;--if da situacao do documento 02 = CANCELADO
      end if;

      --------------------------------------------------------------------------------
      --REGISTRO C110: INFORMAÇÃO COMPLEMENTAR DA NOTA FISCAL (CÓDIGO 01, 1B, 04 e 55)
      --------------------------------------------------------------------------------
      if substr(v_linha,1,5) = '|C110' then
         v_coluna := string_to_array(v_linha,'|');      
         insert into audicdoc (nnumeroapura,
                               nsequendocto,
                               ccodigoinfco,
                               ctxtcplicdoc)
                       values (p_apuracao,
                               v_seq,
                               v_coluna[3],
                               v_coluna[4]);
      end if;
      
      v_contador := v_contador + 1;
      v_linha := x.registro[v_contador];
    
    end loop;--fim do while
  
    -- rotina para importar o arquivo de ENTRADAS e SAIDAS 
    if v_retorno = 'OK' then

       -- apagar os registros do C100
       delete from audandoc
        where nnumeroapura = p_apuracao;
       delete from auditdoc
        where nnumeroapura = p_apuracao;
       delete from audicdoc
        where nnumeroapura = p_apuracao;
       delete from auddocto
        where nnumeroapura = p_apuracao;    

       v_seq := 0;

       -- ENTRADA
       v_contador := 1;
       v_linha  := x.regent[v_contador];
       while (v_retorno = 'OK') and (substr(v_linha,1,5) <> '99999')
       loop
         if substr(v_linha,319,4) = 'C100' then
            -- quando a situacao é 02 (CANCELADO) nao precisa importar (JOAO em 14/04/2014) 
            if substr(v_linha,618,2) <> '02' then
               
               select coalesce(ccodigoparti,'')
                 into v_participante
                 from audparti
                where nnumeroapura = p_apuracao
                  and ncnpj__parti = substr(v_linha,851,14);
               if coalesce(v_participante,'') = '' then
                  RAISE 'Participante ENTRADA não encontrado. CNPJ % ', substr(v_linha,851,14);
               end if;

               v_seq := v_seq + 1;
               --v_itseq := 0;
               insert into auddocto (nnumeroapura,
                                     nsequendocto,
                                     ctipoesdocto,
                                     cindemidocto,
                                     ccodigoparti,
                                     cmodelodocto,
                                     ccodsitdocto,
                                     ccodserdocto,
                                     nnumerodocto,
                                     nchvnfedocto,
                                     ddatemidocto,
                                     ddate_sdocto,
                                     nvlrtotdocto,
                                     nindpagdocto,
                                     nindfredocto,
                                     nvlrfredocto,
                                     nvlrsegdocto,
                                     nvloudadocto,
                                     nvlbcicdocto,
                                     nvlricmdocto,
                                     nbcicstdocto,
                                     nvlicstdocto,
                                     nvlripidocto,
                                     nvlrpisdocto,
                                     nvlrcofdocto,
                                     nvlpistdocto,
                                     nvlcostdocto,
                                     nvlrdesdocto,
                                     nvlabntdocto,
                                     nvlmesedocto)
                             values (p_apuracao,
                                     v_seq,
                                     '0',--substr(v_linha,554,1),
                                     substr(v_linha,555,1),                               
                                     v_participante,--'FOR'||lpad(trim(substr(v_linha,556,60)),9,'0'),
                                     substr(v_linha,616,2),
                                     substr(v_linha,618,2),
                                     substr(v_linha,620,3),
                                     substr(v_linha,623,9),
                                     substr(v_linha,632,44),
                                     substr(v_linha,676,8),
                                     substr(v_linha,684,8),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,692,8),'.',''),' ','')),
                                     substr(v_linha,700,1),
                                     substr(v_linha,701,1),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,702,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,710,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,718,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,726,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,734,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,742,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,750,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,758,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,766,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,774,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,782,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,790,8),'.',''),' ','')),
                                     null,
                                     null,
                                     null);
            end if;--if da situacao do documento 02 = CANCELADO
         end if;
       
         v_contador := v_contador + 1;
         v_linha := x.regent[v_contador];
       end loop;

       -- SAIDA
       v_contador := 1;
       v_linha  := x.regsai[v_contador];
       while (v_retorno = 'OK') and (substr(v_linha,1,5) <> '99999')
       loop
         if substr(v_linha,319,4) = 'C100' then
            -- quando a situacao é 02 (CANCELADO) nao precisa importar (JOAO em 14/04/2014) 
            if substr(v_linha,618,2) <> '02' then

               select coalesce(ccodigoparti,'')
                 into v_participante
                 from audparti
                where nnumeroapura = p_apuracao
                  and ncnpj__parti = substr(v_linha,851,14);
               if coalesce(v_participante,'') = '' then
                  RAISE 'Participante SAIDA não encontrado. CNPJ % ', substr(v_linha,851,14);
               end if;

               v_seq := v_seq + 1;
               insert into auddocto (nnumeroapura,
                                     nsequendocto,
                                     ctipoesdocto,
                                     cindemidocto,
                                     ccodigoparti,
                                     cmodelodocto,
                                     ccodsitdocto,
                                     ccodserdocto,
                                     nnumerodocto,
                                     nchvnfedocto,
                                     ddatemidocto,
                                     ddate_sdocto,
                                     nvlrtotdocto,
                                     nindpagdocto,
                                     nindfredocto,
                                     nvlrfredocto,
                                     nvlrsegdocto,
                                     nvloudadocto,
                                     nvlbcicdocto,
                                     nvlricmdocto,
                                     nbcicstdocto,
                                     nvlicstdocto,
                                     nvlripidocto,
                                     nvlrpisdocto,
                                     nvlrcofdocto,
                                     nvlpistdocto,
                                     nvlcostdocto,
                                     nvlrdesdocto,
                                     nvlabntdocto,
                                     nvlmesedocto)
                             values (p_apuracao,
                                     v_seq,
                                     '1',--substr(v_linha,554,1),
                                     substr(v_linha,555,1),                               
                                     v_participante,--'CLI'||lpad(trim(substr(v_linha,556,60)),9,'0'),
                                     substr(v_linha,616,2),
                                     substr(v_linha,618,2),
                                     substr(v_linha,620,3),
                                     substr(v_linha,623,9),
                                     substr(v_linha,632,44),
                                     substr(v_linha,676,8),
                                     substr(v_linha,684,8),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,692,8),'.',''),' ','')),
                                     substr(v_linha,700,1),
                                     substr(v_linha,701,1),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,702,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,710,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,718,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,726,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,734,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,742,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,750,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,758,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,766,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,774,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,782,8),'.',''),' ','')),
                                     prc_StrToFloatDef(replace(replace(substr(v_linha,790,8),'.',''),' ','')),
                                     null,
                                     null,
                                     null);
            end if;--if da situacao do documento 02 = CANCELADO
         end if;       
         v_contador := v_contador + 1;
         v_linha := x.regsai[v_contador];
       end loop;
    end if;

  end loop;

  return v_retorno;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.prc_carrega_dados_apuracao (p_apuracao bigint)
  OWNER TO postgres;