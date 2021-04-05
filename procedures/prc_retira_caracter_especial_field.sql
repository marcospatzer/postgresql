CREATE OR REPLACE FUNCTION public.prc_retira_caracter_especial_field (
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
  for x in 1..length(p_param)
  loop
    v_limpa := '';
    v_Limpa:=  substr(p_param,x,1);

   if v_Limpa in ('&','$', '#', '@', '%', '(', ')', ',', '*', '(', '!', '¨', '?',
                  '+', '¹','²','³','£','¢','¬','§',chr(92), '|',',', '<','>', '<',':',
                  '^', '}','`','{', 'ª' ,'ª') then
       v_Limpa := '';
    end if;
    if v_Limpa in ('"') then
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