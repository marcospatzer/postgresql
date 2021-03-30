CREATE OR REPLACE FUNCTION public.prc_strtofloatdef (
  p_valor varchar
)
RETURNS numeric AS
$body$
declare

v_retorno  NUMERIC;

begin
  if (p_valor is null) or (p_valor = '') or (p_valor = ' ') then
     v_retorno := 0;
  else
     v_retorno := cast( replace(p_valor,',','.')  as NUMERIC);
  end if;
  return v_retorno;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
