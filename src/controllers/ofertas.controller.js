import connection from "../db/connection.db.js";
import { obtenerCoordenadas } from "../utils/Geocodeo.js";

// ==========================================================
// 1. CREAR OFERTA (AHORA GUARDA COORDENADAS)
// ==========================================================
export const crearOferta = async (req, res) => {
    // 1. Validar sesión
    if (!req.isAuthenticated()) {
        return res.status(401).json({ error: "No autorizado. Inicia sesión como empresa primero." });
    }

    const rut_empresa = req.user.rut; 
    const { modalidad, ubicacion, descripcion, cargo, remuneracion, cant_horas, habilidades } = req.body;

    try {
        if (req.user.tipo !== 'Empresa') {
            return res.status(403).json({ error: "Solo una cuenta de empresa puede publicar ofertas." });
        }

        const empresa = await connection.query('SELECT rut FROM Empresa WHERE rut = $1', [rut_empresa]);
        if (empresa.rows.length === 0) {
            return res.status(403).json({ error: "La cuenta autenticada no tiene perfil de empresa asociado." });
        }
            // Consultar la normativa universitaria vigente.
    const normativaResult = await connection.query(`
        SELECT horas_minimas, plazo_entrega_dias,
               requisitos_academicos
        FROM Normativa_Practica
        WHERE activa = TRUE
         AND fecha_vigencia <= CURRENT_DATE
        ORDER BY fecha_vigencia DESC, id DESC
        LIMIT 1
    `);

    if (normativaResult.rows.length === 0) {
        return res.status(503).json({
            error: "La normativa de prácticas no está configurada."
        });
    }

    const normativa = normativaResult.rows[0];
    const horas = Number(cant_horas);

    if (
        cant_horas === undefined ||
        cant_horas === null ||
        String(cant_horas).trim() === "" ||
        !Number.isInteger(horas) ||
        horas < normativa.horas_minimas
    ) {
        return res.status(400).json({
            error: `La práctica debe contemplar al menos ${normativa.horas_minimas} horas.`
        });
    }
        // 2. Traducir la ubicación a Coordenadas GPS
        let lat = null;
        let lon = null;

        if (modalidad !== 'Remoto') {
            const coordenadas = await obtenerCoordenadas(ubicacion);
            if (coordenadas) {
                lat = coordenadas.latitud;
                lon = coordenadas.longitud;
            }
        }

    // 3. Insertar la práctica incluyendo Latitud y Longitud
    const {
        fecha_limite_postulacion,
        fecha_limite_entrega,
        requisitos_oferta
    } = req.body;

    const queryPractica = `
        INSERT INTO Practica (
            rut_empresa,
            ubicacion,
            cargo,
            cant_horas,
            descripcion,
            modalidad,
            remuneracion,
            latitud,
            longitud,
            requisitos_academicos,
            fecha_limite_postulacion,
            fecha_limite_entrega
        )
        VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
        )
        RETURNING id;
    `;

    const valuesPractica = [
        rut_empresa,
        ubicacion,
        cargo,
        horas,
        descripcion,
        modalidad,
        remuneracion,
        lat,
        lon,
        requisitos_oferta || normativa.requisitos_academicos,
        fecha_limite_postulacion || null,
        fecha_limite_entrega || null
    ];

    const resultPractica = await connection.query(
        queryPractica,
        valuesPractica
    );

        // 4. Insertar las habilidades en la tabla intermedia
        if (habilidades && habilidades.length > 0) {
            for (const id_habilidad of habilidades) {
                const queryHabilidad = `
                    INSERT INTO Habilidades_Practica (id_practica, id_habilidad)
                    VALUES ($1, $2);
                `;
                await connection.query(queryHabilidad, [id_practica, id_habilidad]);
            }
        }

        return res.status(201).json({ 
            mensaje: "Oferta creada exitosamente", 
            id_practica: id_practica 
        });

    } catch (error) {
        console.error("Error al guardar la oferta en BD:", error);
        return res.status(500).json({ error: `Falló la Base de Datos: ${error.message || error.detail || "Error desconocido"}` });
    }
};

// ==========================================================
// 2. OBTENER TODAS LAS OFERTAS (SIN CAMBIOS)
// ==========================================================
export const obtenerOfertas = async (req, res) => {
    try {
        const query = `
            SELECT 
                p.id, p.ubicacion, p.descripcion, p.modalidad, u.nombre AS nombre_empresa,
                COALESCE(
                    (SELECT json_agg(json_build_object('id', h.id, 'nombre', h.nombre, 'categoria', h.categoria) ORDER BY h.categoria, h.nombre)
                     FROM Habilidades_Practica hp JOIN Habilidades h ON hp.id_habilidad = h.id
                     WHERE hp.id_practica = p.id), '[]'::json
                ) AS habilidades
            FROM Practica p
            JOIN Usuarios u ON p.rut_empresa = u.rut
            ORDER BY p.id DESC;
        `;
        const resultado = await connection.query(query);
        return res.status(200).json(resultado.rows);
    } catch (error) {
        console.error("Error al obtener las ofertas de la BD:", error);
        return res.status(500).json({ error: "Error interno del servidor al obtener las ofertas." });
    }
};

// ==========================================================
// 3. MATCHING POR HABILIDADES (SCORE %) (SIN CAMBIOS)
// ==========================================================
export const obtenerOfertasMatching = async (req, res) => {
    if (!req.isAuthenticated()) {
        return res.status(401).json({ error: "No autorizado. Inicia sesión primero." });
    }

    try {
        const habilidadesEstudianteResult = await connection.query(
            `SELECT id_habilidad FROM Habilidades_Estudiante WHERE rut_estudiante = $1`, [req.user.rut]
        );

        const habilidadesEstudiante = new Set(habilidadesEstudianteResult.rows.map((row) => row.id_habilidad));

        const ofertasResult = await connection.query(`
            SELECT
                p.id, u.nombre AS nombre_empresa, p.descripcion, p.modalidad, p.ubicacion,
                COALESCE(array_agg(h.id ORDER BY h.nombre) FILTER (WHERE h.id IS NOT NULL), ARRAY[]::integer[]) AS ids_habilidades,
                COALESCE(array_agg(h.nombre ORDER BY h.nombre) FILTER (WHERE h.nombre IS NOT NULL), ARRAY[]::varchar[]) AS habilidades
            FROM Practica p
            JOIN Usuarios u ON p.rut_empresa = u.rut
            LEFT JOIN Habilidades_Practica hp ON hp.id_practica = p.id
            LEFT JOIN Habilidades h ON h.id = hp.id_habilidad
            GROUP BY p.id, u.nombre, p.descripcion, p.modalidad, p.ubicacion;
        `);

        const ofertas = ofertasResult.rows
            .map((oferta) => {
                const idsHabilidades = oferta.ids_habilidades || [];
                const habilidadesEnComun = idsHabilidades.filter((id) => habilidadesEstudiante.has(id)).length;
                const score = idsHabilidades.length === 0 ? 0 : Math.round((habilidadesEnComun / idsHabilidades.length) * 100);

                return {
                    id: oferta.id, nombre_empresa: oferta.nombre_empresa, descripcion: oferta.descripcion,
                    modalidad: oferta.modalidad, ubicacion: oferta.ubicacion, habilidades: oferta.habilidades || [], score
                };
            })
            .sort((a, b) => b.score - a.score);

        return res.status(200).json(ofertas);
    } catch (error) {
        console.error("Error al obtener las ofertas para matching:", error);
        return res.status(500).json({ error: "Error interno del servidor al obtener las ofertas para matching." });
    }
};

// ==========================================================
// 4. ASIGNAR SUPERVISOR (SIN CAMBIOS)
// ==========================================================
export const asignarSupervisor = async (req,res) => {
    const {rut, nombre, empresa, id, tipo_usuario} = req.body;

    try{
        await connection.query(`
            INSERT INTO Usuarios (rut, nombre, tipo) VALUES ($1, $2, $3) ON CONFLICT (rut) DO NOTHING
        `, [rut, nombre, tipo_usuario]);

        await connection.query(`
            INSERT INTO Supervisor_Practica (rut, nom_empresa) VALUES ($1, $2) ON CONFLICT (rut) DO NOTHING
        `, [rut, empresa]);

        await connection.query (`
            UPDATE practica SET rut_supervisor = $1 WHERE id = $2
        `, [rut, id]);

        return res.status(200).json({ success: true, mensaje: "Supervisor registrado con éxito." });
    } catch (error) {
        console.error("Error al ingresar Supervisor", error);
        return res.status(500).json({ error: "Error interno del servidor al editar oferta." });
    }

};
