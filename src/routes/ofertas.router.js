import { Router } from 'express';
import { asignarSupervisor, crearOferta, obtenerOfertas, obtenerOfertasMatching } from '../controllers/ofertas.controller.js';

const router = Router();

router.post('/ofertas', crearOferta);

router.get('/ofertas', obtenerOfertas);

router.get('/ofertas/matching', obtenerOfertasMatching);

router.put('/supervisor', asignarSupervisor);

//router.post('/estudiante/postular',Postular);

export default router;

