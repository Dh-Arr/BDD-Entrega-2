-- Q1: Consejeros Académicos en Facultades Específicas
-- Se actualizó el nombre de la tabla a pertenece_c

SELECT 
    c.con_nombre, 
    c.con_apellido, 
    e.esta_descripcion, 
    d.dep_descripcion, 
    cons.cons_descripcion
FROM consejero c
JOIN estamento e ON c.esta_codigo = e.esta_codigo
JOIN academico a ON c.con_rut = a.con_rut
JOIN departamento d ON a.dep_codigo = d.dep_codigo
JOIN facultad f ON d.fac_codigo = f.fac_codigo
JOIN especializacion esp ON a.esp_codigo = esp.esp_codigo
JOIN pertenece_c pc ON c.con_rut = pc.con_rut
JOIN consejo cons ON pc.cons_codigo = cons.cons_codigo
WHERE pc.fecha_termino IS NULL
  AND esp.esp_descripcion = 'Ciencias de Datos'
  AND f.fac_descripcion IN ('Fac. Ciencias Empresariales', 'Fac. Ingeniería');

-- Q2: Consejeros del Consejo Universitario sin asistencia en Septiembre y Octubre 2025 a sesiones sin temas resolutivos
-- Se actualizó el nombre de la tabla a pertenece_c

SELECT DISTINCT c.con_nombre, c.con_apellido
FROM consejero c
INNER JOIN pertenece_c pc ON c.con_rut = pc.con_rut
INNER JOIN consejo co ON pc.cons_codigo = co.cons_codigo
WHERE co.cons_descripcion = 'Consejo Universitario'
  AND (pc.fecha_termino IS NULL OR pc.fecha_termino >= CURRENT_DATE)
  AND c.con_rut NOT IN (
      SELECT ac.con_rut
      FROM asiste_c ac
      INNER JOIN sesion s ON ac.ses_codigo = s.ses_codigo
      WHERE EXTRACT(YEAR FROM s.ses_fecha) = 2025
        AND EXTRACT(MONTH FROM s.ses_fecha) IN (9, 10)
        AND s.ses_codigo NOT IN (
            SELECT t.ses_codigo
            FROM tema t
            INNER JOIN propone p ON t.tem_codigo = p.tem_codigo
            WHERE t.tem_tipo = 'Resolutivo'
        )
  );

-- Q3: Resumen Sesiones 2025
-- Se actualizó el nombre de la tabla a pertenece_c

SELECT 
    co.cons_descripcion AS Consejo,
    s.ses_codigo AS Codigo_Sesion,
    COUNT(DISTINCT t.tem_codigo) AS Numero_Temas,
    COUNT(DISTINCT CASE 
        WHEN u.con_rut IS NOT NULL AND DATE(u.fecha) = DATE(s.ses_fecha) 
        THEN ac.con_rut 
    END) AS Consejeros_Con_Vehiculo,
    COUNT(DISTINCT CASE 
        WHEN u.con_rut IS NULL OR DATE(u.fecha) != DATE(s.ses_fecha)
        THEN ac.con_rut 
    END) AS Consejeros_Sin_Vehiculo
FROM sesion s
JOIN tema t ON s.ses_codigo = t.ses_codigo
JOIN propone_c pc ON t.tem_codigo = pc.tem_codigo
JOIN asiste_c ac ON s.ses_codigo = ac.ses_codigo
JOIN pertenece_c pcon ON ac.con_rut = pcon.con_rut
JOIN consejo co ON pcon.cons_codigo = co.cons_codigo
LEFT JOIN usa u ON ac.con_rut = u.con_rut AND DATE(u.fecha) = DATE(s.ses_fecha)
WHERE EXTRACT(YEAR FROM s.ses_fecha) = 2025
  AND EXTRACT(MONTH FROM s.ses_fecha) BETWEEN 1 AND 11
  AND (pcon.fecha_termino IS NULL OR pcon.fecha_termino >= s.ses_fecha)
GROUP BY co.cons_descripcion, s.ses_codigo
ORDER BY s.ses_codigo;

-- Q4: Vista y Consejero con Mayor Asistencia 2025
-- Se actualizó el nombre de la tabla a pertenece_c

CREATE OR REPLACE VIEW vista_asistencia_2025 AS
SELECT 
    c.con_rut,
    c.con_nombre,
    c.con_apellido,
    e.esta_descripcion AS estamento,
    co.cons_descripcion AS consejo,
    COUNT(DISTINCT s.ses_codigo) AS sesiones_totales,
    COUNT(DISTINCT ac.ses_codigo) AS sesiones_asistidas,
    ROUND(
        (COUNT(DISTINCT ac.ses_codigo)::NUMERIC / 
         NULLIF(COUNT(DISTINCT s.ses_codigo), 0)) * 100, 
        2
    ) AS porcentaje_asistencia
FROM consejero c
JOIN pertenece_c pc ON c.con_rut = pc.con_rut
JOIN consejo co ON pc.cons_codigo = co.cons_codigo
JOIN estamento e ON c.esta_codigo = e.esta_codigo
CROSS JOIN sesion s
LEFT JOIN asiste_c ac ON c.con_rut = ac.con_rut AND s.ses_codigo = ac.ses_codigo
WHERE pc.fecha_termino IS NULL
  AND EXTRACT(YEAR FROM s.ses_fecha) = 2025
  AND EXTRACT(MONTH FROM s.ses_fecha) BETWEEN 1 AND 11
GROUP BY c.con_rut, c.con_nombre, c.con_apellido, e.esta_descripcion, co.cons_descripcion;

-- Consulta del consejero con mayor asistencia
SELECT 
    con_nombre,
    con_apellido,
    estamento,
    porcentaje_asistencia
FROM vista_asistencia_2025
WHERE porcentaje_asistencia = (
    SELECT MAX(porcentaje_asistencia)
    FROM vista_asistencia_2025
);
-- FIN CONSULTAS
