import { Router } from 'express';
import connection from "../db/connection.db.js";
import {upload} from '../services/middlewares/upload.js';

const router = Router()

router.post('/subir_informe', upload.single('pdf_documento'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({error: 'No hay un archivo que subir'});
        }

        const {rut_estudiante, id_practica, rut_supervisor} = req.body;
        const rutaRelativa = `/uploads/${req.file.filename}`;

        const subir_archivo = await connection.query(`
            INSERT INTO practica_en_proceso (rut, id_practica, rut_supervisor, ruta_archivo, estado)
            VALUES ($1, $2, $3, $4, 'Enviado para revisar')
            ON CONFLICT (rut, id_practica)
            DO UPDATE SET
                ruta_archivo = EXCLUDED.ruta_archivo,
                estado = 'Enviado para revisar'
            RETURNING *;
            `, [rut_estudiante, id_practica, rut_supervisor, rutaRelativa]);
        res.json({
            mensaje: 'Archivo enviado con éxito',
            datos: subir_archivo.rows[0]
        });   
    } catch(error){
        console.error("Error en el controlador de subida:", error);
        res.status(500).json({error: 'Error interno al procesar el archivo.'});
    }
} );

import { cambiarEstado, ESTADOS } from '../services/estadoPostulacion.service.js';

router.post('/subir_informe', upload.single('pdf_documento'), async (req, res) => {
    if (!req.isAuthenticated() || req.user.tipo !== 'Estudiante') {
        return res.status(403).json({ error: 'Acceso denegado' });
    }
    try {
        if (!req.file) return res.status(400).json({ error: 'No hay un archivo que subir' });

        const { id_practica } = req.body;
        const rutaRelativa = `/uploads/${req.file.filename}`;

        await cambiarEstado({
            rut: req.user.rut,                 // de la sesión, no del body
            idPractica: id_practica,
            nuevoEstado: ESTADOS.INFORME_ENVIADO,
            actor: req.user.rut,
            rutaArchivo: rutaRelativa,
        });

        const { rows } = await connection.query(
            'SELECT * FROM practica_en_proceso WHERE rut = $1 AND id_practica = $2',
            [req.user.rut, id_practica]);
        res.json({ mensaje: 'Archivo enviado con éxito', datos: rows[0] });
    } catch (error) {
        console.error('Error en el controlador de subida:', error);
        res.status(error.status || 500).json({ error: error.status === 409
            ? 'Solo puedes subir el informe de una práctica aceptada.'
            : 'Error interno al procesar el archivo.' });
    }
});

export default router;