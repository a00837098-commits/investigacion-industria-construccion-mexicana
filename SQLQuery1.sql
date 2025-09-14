-- Agregaciones

CREATE VIEW vw_tasa_ocupacion_promedio AS
SELECT id_periodo, AVG(tasa_ocupacion) AS promedio_ocupacion
FROM dbo.dim_tasa_ocupacion
GROUP BY id_periodo


-- Totales por entidad:

CREATE VIEW vw_remuneraciones_totales_entidad AS
SELECT cve_entidad, SUM(remuneraciones_totales) AS total_remuneraciones
FROM dbo.dim_remuneraciones_totales
GROUP BY cve_entidad

-- Indicadores
CREATE VIEW vw_remuneraciones_ratio AS
SELECT r.id_periodo, r.cve_entidad,
       r.remuneraciones_obreros * 1.0 / t.remuneraciones_totales AS ratio_obrero_total
FROM dbo.dim_remuneraciones_obreros r
JOIN dbo.dim_remuneraciones_totales t
  ON r.id_periodo = t.id_periodo AND r.cve_entidad = t.cve_entidad

-- Normalización

CREATE OR ALTER VIEW vw_fact_empleo AS
SELECT 
    p.id_periodo,
    e.cve_entidad,
    t.tasa_ocupacion,
    rt.remuneraciones_totales,
    ro.remuneraciones_obreros,
    gm.gastos_materiales,
    gb.gastos_bienes_servicios,
    cm.consumo_materiales,
    po.personal_ocupado,
    ho.horas_trabajadas_obreros,
    ha.horas_trabajadas_admin,
    hp.horas_trabajadas_propietarios,
    dt.dias_trabajo
FROM dbo.dim_periodos p
JOIN dbo.dim_tasa_ocupacion t 
    ON p.id_periodo = t.id_periodo
JOIN dbo.dim_entidades e
    ON t.cve_entidad = e.cve_entidad
JOIN dbo.dim_remuneraciones_totales rt 
    ON p.id_periodo = rt.id_periodo AND e.cve_entidad = rt.cve_entidad
JOIN dbo.dim_remuneraciones_obreros ro 
    ON p.id_periodo = ro.id_periodo AND e.cve_entidad = ro.cve_entidad
JOIN dbo.dim_gastos_materiales gm 
    ON p.id_periodo = gm.id_periodo AND e.cve_entidad = gm.cve_entidad
JOIN dbo.dim_gastos_bienes_servicios gb 
    ON p.id_periodo = gb.id_periodo AND e.cve_entidad = gb.cve_entidad
JOIN dbo.dim_consumo_materiales cm 
    ON p.id_periodo = cm.id_periodo AND e.cve_entidad = cm.cve_entidad
JOIN dbo.dim_personal_ocupado po 
    ON p.id_periodo = po.id_periodo AND e.cve_entidad = po.cve_entidad
JOIN dbo.dim_horas_trabajadas_obreros ho 
    ON p.id_periodo = ho.id_periodo AND e.cve_entidad = ho.cve_entidad
JOIN dbo.dim_horas_trabajadas_admin ha 
    ON p.id_periodo = ha.id_periodo AND e.cve_entidad = ha.cve_entidad
JOIN dbo.dim_horas_trabajadas_propietarios hp 
    ON p.id_periodo = hp.id_periodo AND e.cve_entidad = hp.cve_entidad
JOIN dbo.dim_dias_trabajo dt 
    ON p.id_periodo = dt.id_periodo AND e.cve_entidad = dt.cve_entidad;


--Tasa de ocupacion
CREATE OR ALTER VIEW vw_tasa_ocupacion_nacional AS
SELECT 
    p.id_periodo,
    AVG(t.tasa_ocupacion) AS promedio_nacional,
    MIN(t.tasa_ocupacion) AS min_ocupacion,
    MAX(t.tasa_ocupacion) AS max_ocupacion
FROM dbo.dim_tasa_ocupacion t
JOIN dbo.dim_periodos p ON t.id_periodo = p.id_periodo
GROUP BY p.id_periodo

--Remuneraciones en cuanto a obreros vs totales
CREATE OR ALTER VIEW vw_remuneraciones_ratio AS
SELECT 
    ro.id_periodo,
    ro.cve_entidad,
    ro.remuneraciones_obreros,
    rt.remuneraciones_totales,
    CAST(ro.remuneraciones_obreros AS FLOAT) / NULLIF(rt.remuneraciones_totales,0) AS ratio_obrero_total
FROM dbo.dim_remuneraciones_obreros ro
JOIN dbo.dim_remuneraciones_totales rt
    ON ro.id_periodo = rt.id_periodo AND ro.cve_entidad = rt.cve_entidad
JOIN dbo.dim_periodos p
    ON ro.id_periodo = p.id_periodo;

--Gasto en materiales por personal ocupado

CREATE OR ALTER VIEW vw_productividad_obras AS
SELECT 
    vo.id_periodo,
    vo.cve_entidad,
    vo.valor_obras_zona,
    ho.horas_trabajadas_obreros + ha.horas_trabajadas_admin + hp.horas_trabajadas_propietarios AS total_horas,
    CAST(vo.valor_obras_zona AS FLOAT) / NULLIF(
        (ho.horas_trabajadas_obreros + ha.horas_trabajadas_admin + hp.horas_trabajadas_propietarios),0
    ) AS valor_por_hora
FROM dbo.dim_valor_obras_zona vo
JOIN dbo.dim_horas_trabajadas_obreros ho
    ON vo.id_periodo = ho.id_periodo AND vo.cve_entidad = ho.cve_entidad
JOIN dbo.dim_horas_trabajadas_admin ha
    ON vo.id_periodo = ha.id_periodo AND vo.cve_entidad = ha.cve_entidad
JOIN dbo.dim_horas_trabajadas_propietarios hp
    ON vo.id_periodo = hp.id_periodo AND vo.cve_entidad = hp.cve_entidad;

--Valor de obras por hora trabajada
CREATE OR ALTER VIEW vw_productividad_obras AS
SELECT 
    vo.id_periodo,
    vo.cve_entidad,
    vo.valor_obras_zona,
    ho.horas_trabajadas_obreros + ha.horas_trabajadas_admin + hp.horas_trabajadas_propietarios AS total_horas,
    CAST(vo.valor_obras_zona AS FLOAT) / NULLIF(
        (ho.horas_trabajadas_obreros + ha.horas_trabajadas_admin + hp.horas_trabajadas_propietarios),0
    ) AS valor_por_hora
FROM dbo.dim_valor_obras_zona vo
JOIN dbo.dim_horas_trabajadas_obreros ho
    ON vo.id_periodo = ho.id_periodo AND vo.cve_entidad = ho.cve_entidad
JOIN dbo.dim_horas_trabajadas_admin ha
    ON vo.id_periodo = ha.id_periodo AND vo.cve_entidad = ha.cve_entidad
JOIN dbo.dim_horas_trabajadas_propietarios hp
    ON vo.id_periodo = hp.id_periodo AND vo.cve_entidad = hp.cve_entidad;

-- Jornada promedio 
CREATE OR ALTER VIEW vw_jornada_promedio AS
SELECT 
    dt.id_periodo,
    dt.cve_entidad,
    dt.dias_trabajo,
    ho.horas_trabajadas_obreros,
    CAST(ho.horas_trabajadas_obreros AS FLOAT) / NULLIF(dt.dias_trabajo,0) AS horas_por_dia
FROM dbo.dim_dias_trabajo dt
JOIN dbo.dim_horas_trabajadas_obreros ho
    ON dt.id_periodo = ho.id_periodo AND dt.cve_entidad = ho.cve_entidad;

-- evolucion PIB
CREATE OR ALTER VIEW vw_pib_evolucion AS
SELECT 
    Trimestres,
    PIB_total,
    PIB_corriente
FROM dbo.pib;

--participacion por sector
CREATE OR ALTER VIEW vw_pib_participacion_sectorial AS
SELECT 
    Trimestres,
    Construccion,
    Mineria,
    [Energía_agua_y_gas],
    Manufactureras,
    Total_actividades_secundaria,
    CAST(Construccion AS FLOAT) / NULLIF(Total_actividades_secundaria,0) AS pct_construccion,
    CAST(Mineria AS FLOAT) / NULLIF(Total_actividades_secundaria,0) AS pct_mineria,
    CAST([Energía_agua_y_gas] AS FLOAT) / NULLIF(Total_actividades_secundaria,0) AS pct_energia,
    CAST(Manufactureras AS FLOAT) / NULLIF(Total_actividades_secundaria,0) AS pct_manufactureras
FROM dbo.pib;

-- crecimiento trimestral
CREATE OR ALTER VIEW vw_pib_crecimiento AS
SELECT 
    Trimestres,
    PIB_total,
    PIB_corriente,
    LAG(PIB_total) OVER (ORDER BY Trimestres) AS pib_total_prev,
    (PIB_total - LAG(PIB_total) OVER (ORDER BY Trimestres)) * 1.0 / 
        NULLIF(LAG(PIB_total) OVER (ORDER BY Trimestres),0) AS crecimiento_total,
    (PIB_corriente - LAG(PIB_corriente) OVER (ORDER BY Trimestres)) * 1.0 / 
        NULLIF(LAG(PIB_corriente) OVER (ORDER BY Trimestres),0) AS crecimiento_corriente
FROM dbo.pib;

-- ranking por sectores
CREATE OR ALTER VIEW vw_pib_ranking_sectorial AS
SELECT 
    Trimestres,
    'Construccion' AS sector, Construccion AS valor
FROM dbo.pib
UNION ALL
SELECT Trimestres, 'Mineria', Mineria FROM dbo.pib
UNION ALL
SELECT Trimestres, 'Energía_agua_y_gas', [Energía_agua_y_gas] FROM dbo.pib
UNION ALL
SELECT Trimestres, 'Manufactureras', Manufactureras FROM dbo.pib;

UPDATE dbo.dim_entidades
SET region = CASE 
    -- Noroeste
    WHEN cve_entidad IN (2, 3, 26, 25, 8) 
        THEN 'Noroeste'
        
    -- Noreste
    WHEN cve_entidad IN (5, 19, 28) 
        THEN 'Noreste'
        
    -- Centro-Norte
    WHEN cve_entidad IN (10, 32, 24, 1, 18, 14, 6, 16) 
        THEN 'Centro-Norte'
        
    -- Centro-Sur
    WHEN cve_entidad IN (22, 11, 13, 15, 9, 17, 29, 21) 
        THEN 'Centro-Sur'
        
    -- Sur-Sureste
    WHEN cve_entidad IN (12, 20, 7, 30, 27, 4, 31, 23) 
        THEN 'Sur-Sureste'
        
    ELSE 'Otra'
END;
