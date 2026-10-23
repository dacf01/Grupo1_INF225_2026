import { Router } from 'express';
import { GoogleGenAI, Type } from '@google/genai';
import fs from 'fs/promises';
import path from 'path';
import connection from '../db/connection.db.js';

const router = Router();

// Inicializar Gemini con la API KEY definida en el archivo .env
const ai = new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY
});

// Directorio donde se almacenan los informes.
// Debe coincidir con la ubicación real de los archivos en el servidor Docker.
const DIRECTORIO_UPLOADS = '/app/uploads';

// Endpoint para generar el resumen de un informe mediante IA.
// Si un id_practica corresponde a varios estudiantes, se debe enviar también el RUT.
router.get('/ia/resumen/:id_practica', async (req, res) => {
    const { id_practica } = req.params;
    const { rut } = req.query;

    try {
        // 1. Validar la configuración de Gemini.
        if (!process.env.GEMINI_API_KEY) {
            console.error('No está configurada GEMINI_API_KEY.');

            return res.status(500).json({
                error: 'El servicio de inteligencia artificial no está configurado.'
            });
        }

        // 2. Validar el identificador de la práctica.
        if (!/^\d+$/.test(id_practica) || Number(id_practica) <= 0) {
            return res.status(400).json({
                error: 'El identificador de la práctica no es válido.'
            });
        }

        // 3. Buscar el informe asociado a la práctica.
        // Cuando se proporciona el RUT, se identifica el informe del estudiante.
        let query;
        let parametros;

        if (typeof rut === 'string' && rut.trim() !== '') {
            query = `
                SELECT rut, id_practica, ruta_archivo
                FROM practica_en_proceso
                WHERE id_practica = $1
                  AND rut = $2
                LIMIT 1
            `;

            parametros = [Number(id_practica), rut.trim()];
        } else {
            query = `
                SELECT rut, id_practica, ruta_archivo
                FROM practica_en_proceso
                WHERE id_practica = $1
                  AND ruta_archivo IS NOT NULL
                  AND ruta_archivo <> ''
                LIMIT 2
            `;

            parametros = [Number(id_practica)];
        }

        const resultado = await connection.query(query, parametros);

        if (resultado.rows.length === 0) {
            return res.status(404).json({
                error: 'No se encontró un informe para la práctica y el estudiante indicados.'
            });
        }

        // Si no se indicó el RUT y hay varios informes, no elegir uno arbitrariamente.
        if (!rut && resultado.rows.length > 1) {
            return res.status(400).json({
                error: 'Esta práctica tiene varios informes. Debes identificar al estudiante.'
            });
        }

        const informe = resultado.rows[0];

        if (!informe.ruta_archivo) {
            return res.status(404).json({
                error: 'El estudiante no tiene un informe subido.'
            });
        }

        // 4. Resolver la ruta del archivo dentro del directorio autorizado.
        // Se aceptan rutas guardadas como /uploads/informe.pdf o solo informe.pdf.
        const nombreArchivo = path.basename(
            informe.ruta_archivo.replace(/\\/g, '/')
        );

        if (
            !nombreArchivo ||
            nombreArchivo === '.' ||
            nombreArchivo === '..'
        ) {
            return res.status(400).json({
                error: 'La ruta del informe no es válida.'
            });
        }

        const rutaAbsolutaPDF = path.join(
            DIRECTORIO_UPLOADS,
            nombreArchivo
        );

        // 5. Leer el archivo y comprobar que sea un PDF.
        let pdfBuffer;

        try {
            pdfBuffer = await fs.readFile(rutaAbsolutaPDF);
        } catch (error) {
            if (error.code === 'ENOENT') {
                return res.status(404).json({
                    error: 'El archivo del informe no se encuentra en el servidor.'
                });
            }

            throw error;
        }

        // Validación básica de la firma del PDF.
        if (
            pdfBuffer.length < 5 ||
            pdfBuffer.subarray(0, 5).toString('ascii') !== '%PDF-'
        ) {
            return res.status(400).json({
                error: 'El archivo almacenado no es un PDF válido.'
            });
        }

        // Evitar procesar documentos excesivamente grandes.
        const TAMANO_MAXIMO = 20 * 1024 * 1024;

        if (pdfBuffer.length > TAMANO_MAXIMO) {
            return res.status(413).json({
                error: 'El informe supera el tamaño máximo permitido de 20 MB.'
            });
        }

        const pdfBase64 = pdfBuffer.toString('base64');

        // 6. Enviar el informe a Gemini y solicitar un resumen estructurado.
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',

            contents: [
                {
                    inlineData: {
                        mimeType: 'application/pdf',
                        data: pdfBase64
                    }
                },
                {
                    text: `
                        Eres un asistente académico encargado de analizar
                        informes de práctica profesional de una universidad.

                        Analiza el documento adjunto y devuelve información
                        exclusivamente basada en su contenido.

                        Instrucciones:
                        - No inventes información ni completes datos ausentes
                          mediante suposiciones.
                        - Si un dato no aparece o no puede determinarse con
                          seguridad, devuelve una cadena vacía para ese campo.
                        - Extrae el RUT del estudiante tal como aparece
                          en el documento.
                        - Identifica el nombre de la empresa o institución.
                        - Identifica las horas de práctica explícitamente
                          declaradas en el informe.
                        - No confundas las horas de práctica con horas de
                          asignaturas, capacitaciones u otras actividades.
                        - Resume las principales actividades, proyectos,
                          herramientas utilizadas y aportes del estudiante.
                        - Redacta el resumen ejecutivo en español formal,
                          de manera clara, objetiva y coherente.
                        - No afirmes que las horas, la identidad o los datos
                          institucionales han sido verificados externamente.
                        - Si existen contradicciones en el documento,
                          indícalas en observaciones.

                        Devuelve los campos solicitados con la estructura
                        JSON definida.
                    `
                }
            ],

            config: {
                responseMimeType: 'application/json',

                responseSchema: {
                    type: Type.OBJECT,

                    properties: {
                        rut_detectado: {
                            type: Type.STRING,
                            description: 'RUT del estudiante identificado en el informe. Cadena vacía si no aparece.'
                        },

                        empresa_detectada: {
                            type: Type.STRING,
                            description: 'Nombre de la empresa o institución identificada en el informe. Cadena vacía si no aparece.'
                        },

                        horas_detectadas: {
                            type: Type.STRING,
                            description: 'Cantidad de horas de práctica explícitamente declaradas en el documento. Cadena vacía si no se puede determinar.'
                        },

                        resumen_ejecutivo: {
                            type: Type.STRING,
                            description: 'Resumen de las actividades, proyectos, herramientas y aportes principales del estudiante.'
                        },

                        observaciones: {
                            type: Type.ARRAY,
                            items: {
                                type: Type.STRING
                            },
                            description: 'Advertencias sobre información ausente, ambigua o contradictoria en el informe.'
                        }
                    },

                    required: [
                        'rut_detectado',
                        'empresa_detectada',
                        'horas_detectadas',
                        'resumen_ejecutivo',
                        'observaciones'
                    ]
                }
            }
        });

        // 7. Validar la respuesta generada por Gemini.
        if (!response.text) {
            return res.status(502).json({
                error: 'La IA no generó una respuesta para el informe.'
            });
        }

        let datosIA;

        try {
            datosIA = JSON.parse(response.text);
        } catch (error) {
            console.error('La IA devolvió una respuesta JSON inválida:', error);

            return res.status(502).json({
                error: 'No fue posible interpretar la respuesta de la IA.'
            });
        }

        // 8. Responder con el resumen estructurado para el frontend.
        return res.status(200).json({
            id_practica: Number(informe.id_practica),
            rut_estudiante: informe.rut,
            ...datosIA
        });

    } catch (error) {
        console.error('Error al procesar el informe mediante IA:', error);

        return res.status(500).json({
            error: 'Ocurrió un error al procesar el informe mediante inteligencia artificial.'
        });
    }
});

export default router;