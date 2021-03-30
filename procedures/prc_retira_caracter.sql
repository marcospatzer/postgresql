CREATE OR REPLACE FUNCTION public.prc_retira_caracter (
  p_param varchar
)
RETURNS varchar AS
$body$
declare
 v_Limpa     varchar;
 v_variavel  varchar;
 x           integer;
 v_tamanho   integer;

BEGIN
  v_limpa := '';
  if p_param is null then
     v_tamanho := 0;
  else
     v_tamanho := length(p_param);
  end if;
  x := 1;
  for x in 1..v_tamanho
  loop
    v_variavel :=  substr((lpad(p_param,v_tamanho,'-')),X,1);
    if v_variavel in ('0','1','2','3','4','5','6','7','8','9','0') then
       v_Limpa := v_Limpa || v_variavel;
    end if;
  end loop;
  return v_Limpa;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION public.prc_retira_caracter (p_param varchar)
  OWNER TO postgres;