import React, { useEffect, useState } from 'react';
import './FormularioOferta.css';

const OPCIONES_MODALIDAD = ["Presencial", "Remoto", "Híbrido"];

const FormularioOferta = ({ volverAlHome }) => {
  const [catalogoHabilidades, setCatalogoHabilidades] = useState([]);
  const [formData, setFormData] = useState({
    modalidad: '',
    ubicacion: '', // Aquí se guardará la dirección exacta en texto
    descripcion: '',
    cargo: '',
    remuneracion: '',
    cant_horas: '',
    habilidades: [] 
  });
  const [errores, setErrores] = useState({});

  useEffect(() => {
    const cargarHabilidades = async () => {
      try {
        const respuesta = await fetch('http://localhost:8000/api/habilidades');

        if (!respuesta.ok) {
          throw new Error('No se pudo cargar el catálogo de habilidades.');
        }

        const habilidades = await respuesta.json();
        setCatalogoHabilidades(habilidades);
      } catch (error) {
        console.error("Error cargando las habilidades:", error);
      }
    };

    cargarHabilidades();
  }, []);

  const habilidadesPorCategoria = catalogoHabilidades.reduce((categorias, habilidad) => {
    if (!categorias[habilidad.categoria]) {
      categorias[habilidad.categoria] = [];
    }

    categorias[habilidad.categoria].push(habilidad);
    return categorias;
  }, {});

  const handleChange = (e) => {
    const { name, value } = e.target; 
    setFormData({ ...formData, [name]: value , requisitos_oferta: '', fecha_limite_postulacion: '', fecha_limite_entrega: ''});
    if (errores[name]) setErrores({ ...errores, [name]: null });
  };

  const handleCheckboxChange = (idHabilidad) => {
    const nuevasHabilidades = formData.habilidades.includes(idHabilidad)
      ? formData.habilidades.filter(h => h !== idHabilidad) 
      : [...formData.habilidades, idHabilidad];             

    setFormData({ ...formData, habilidades: nuevasHabilidades });
    if (errores.habilidades && nuevasHabilidades.length > 0) {
      setErrores({ ...errores, habilidades: null });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault(); 
    let nuevosErrores = {};

    if (!formData.modalidad) nuevosErrores.modalidad = "La modalidad es obligatoria.";
    if (!formData.ubicacion.trim()) nuevosErrores.ubicacion = "La dirección exacta es obligatoria.";
    if (!formData.descripcion.trim()) nuevosErrores.descripcion = "La descripción no puede estar vacía.";
    if (formData.habilidades.length === 0) nuevosErrores.habilidades = "Selecciona al menos una habilidad.";

    if (Object.keys(nuevosErrores).length > 0) {
      setErrores(nuevosErrores);
      return; 
    }

    try {
      const respuesta = await fetch('http://localhost:8000/api/ofertas', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        credentials: 'include', 
        body: JSON.stringify(formData)
      });

      if (respuesta.ok) {
        alert("¡Oferta publicada exitosamente!");
        volverAlHome(); // Redirecciona automáticamente al panel tras el éxito
      } else {
        const errorData = await respuesta.json().catch(() => null);
        const mensajeError = errorData?.error || "Error al publicar la oferta. Verifica tu sesión o los datos ingresados.";
        alert(mensajeError);
      }
    } catch (error) {
      console.error("Error conectando con el servidor:", error);
      alert("Error de conexión al servidor.");
    }
  };

  return (
    <div className="formulario-container">
      <div className="formulario-card">
        
        <div className="formulario-header">
          <h2>Publicar Nueva Oferta</h2>
        </div>
        
        <form onSubmit={handleSubmit}>
          
          <div className="form-group">
            <label className="main-label">Modalidad de trabajo</label>
            <select name="modalidad" value={formData.modalidad} onChange={handleChange} className="form-select">
              <option value="">-- Selecciona --</option>
              {OPCIONES_MODALIDAD.map(opcion => (
                <option key={opcion} value={opcion}>{opcion}</option>
              ))}
            </select>
            {errores.modalidad && <span className="error-text">⚠ {errores.modalidad}</span>}
          </div>

          {/* CAMBIO CLAVE: Entrada de texto libre para direcciones GPS legibles */}
          <div className="form-group">
            <label className="main-label">Dirección de la Empresa / Sucursal</label>
            <input 
              type="text" 
              name="ubicacion" 
              value={formData.ubicacion} 
              onChange={handleChange}
              placeholder="Ej: Pasaje Cecilia 6252, San Joaquín"
              className="form-input"
              disabled={formData.modalidad === 'Remoto'} // Se deshabilita opcionalmente si es remoto
            />
            {errores.ubicacion && <span className="error-text">⚠ {errores.ubicacion}</span>}
          </div>

          <div className="form-group">
            <label className="main-label">Descripción de la práctica</label>
            <textarea 
              name="descripcion"
              value={formData.descripcion}
              onChange={handleChange}
              placeholder="Ej: Buscamos un estudiante motivado para trabajar en el desarrollo de nuestra nueva plataforma interna..."
              className="form-textarea"
            />
            {errores.descripcion && <span className="error-text">⚠ {errores.descripcion}</span>}
          </div>

          <div className="form-group">
            <label className="main-label">Cargo (Opcional)</label>
            <input type="text" name="cargo" value={formData.cargo} onChange={handleChange} placeholder="Ej: Desarrollador Backend Junior" />  
          </div>

          <div className="form-group">
            <label className="main-label">Cantidad de Horas</label>
            <input type="text" name="cant_horas" value={formData.cant_horas} onChange={handleChange} placeholder="Ej: 320" />  
          </div>

          <div className="form-group">
            <label className="main-label">Remuneración (CLP)</label>
            <input type="text" name="remuneracion" value={formData.remuneracion} onChange={handleChange} placeholder="Ej: 250000 o No remunerada" />  
          </div>

          <div className="form-group">
            <label className="main-label">Requerimientos del perfil</label>
            {errores.habilidades && <span className="error-text" style={{marginBottom: '15px'}}>⚠ {errores.habilidades}</span>}
            
            {Object.entries(habilidadesPorCategoria).map(([categoria, listaHabilidades]) => (
              <div key={categoria} className="categoria-habilidades">
                <h4 className="categoria-titulo">{categoria}</h4>
                <div className="checkbox-grid">
                  {listaHabilidades.map(hab => (
                    <label key={hab.id} className="checkbox-label">
                      <input 
                        type="checkbox" 
                        value={hab.id}
                        checked={formData.habilidades.includes(hab.id)}
                        onChange={() => handleCheckboxChange(hab.id)}
                      />
                      {hab.nombre}
                    </label>
                  ))}
                </div>
              </div>
            ))}
          </div>

          <div className='buttons'>
            <button type="submit" className="btn-submit">Publicar Ahora</button>
            {/* CORRECCIÓN: type="button" evita que este botón valide o envíe el formulario */}
            <button type="button" className="volveralhome" onClick={volverAlHome}>Volver al Home</button>
          </div>
           <div className="form-group">
          <label className="main-label">
             Requisitos académicos específicos
          </label>
          <textarea
              name="requisitos_oferta"
             value={formData.requisitos_oferta}
             onChange={handleChange}
              placeholder="Ej.: asignaturas aprobadas o requisitos del área"
              className="form-textarea"
            />
          </div>

          <div className="form-group">
            <label className="main-label">
              Fecha límite de postulación
            </label>
          <input
            type="date"
            name="fecha_limite_postulacion"
            value={formData.fecha_limite_postulacion}
            onChange={handleChange}
            className="form-input"
          />
          </div>

          <div className="form-group">
            <label className="main-label">
             Fecha límite de entrega
          </label>
            <input
             type="date"
             name="fecha_limite_entrega"
             value={formData.fecha_limite_entrega}
             onChange={handleChange}
             className="form-input"
              />
          </div>
        </form>
      </div>
    </div>
  );
};



export default FormularioOferta;