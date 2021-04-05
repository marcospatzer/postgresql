CREATE OR REPLACE FUNCTION public.prc_retira_caracter_acentuacao (
  p_param varchar
)
RETURNS varchar AS
$body$
declare
 v_Limpa     varchar(200);
 v_variavel  varchar(200);
 x           integer;

BEGIN
  v_variavel := '';
  x := 1;
  for x in 1..65
  loop
    v_limpa := '';
    v_Limpa:=  substr((rpad(p_param,65,']')),x,1);
    if v_Limpa in ('á','à','â','ä','ã') then
       v_Limpa := 'a';
    end if;
    if v_Limpa in ('é','è','ê','ë') then
       v_Limpa := 'e';
    end if;
    if v_Limpa in ('í','ì','î','ï') then
       v_Limpa := 'i';
    end if;
   if v_Limpa in ('ó','ò','ô','ö','õ') then
       v_Limpa := 'o';
    end if;
   if v_Limpa in ('ú','ù','û','ü') then
       v_Limpa := 'u';
    end if;
   if v_Limpa in ('ñ') then
       v_Limpa := 'n';
    end if;
    if v_Limpa in ('ç') then
       v_Limpa := 'c';
    end if;
    if v_Limpa in ('Á','À','Â','Ä','Ã') then
       v_Limpa := 'A';
    end if;
    if v_Limpa in ('É','È','Ê','Ë') then
       v_Limpa := 'E';
    end if;
    if v_Limpa in ('Í','Ì','Ï','Î') then
       v_Limpa := 'I';
    end if;
    if v_Limpa in ('Ó','Ò','Ô','Ö','Õ') then
       v_Limpa := 'O';
    end if;
    if v_Limpa in ('Ú','Ù','Û','Ü') then
       v_Limpa := 'U';
    end if;
    if v_Limpa in ('Ñ') then
       v_Limpa := 'N';
    end if;
    if v_Limpa in ('Ç') then
       v_Limpa := 'C';
    end if;
    if v_Limpa in (']') then
       v_Limpa := '';
    end if;
    if v_Limpa in ('º') then
       v_Limpa := '';
    end if;
    if v_Limpa in ('&') then
       v_Limpa := '';
    end if;

    v_variavel := v_variavel||v_limpa;
  end loop;
  return v_variavel;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;