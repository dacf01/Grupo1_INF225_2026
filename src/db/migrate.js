import { readFile, access } from 'node:fs/promises'
import { constants } from 'node:fs'
import { resolve } from 'node:path'
import { Client } from 'pg'
import { dbConfig } from '../config/database.js'

const schemaPath = resolve(process.cwd(), './esquema.sql')

const ensureSchemaExists = async () => {
  try {
    await access(schemaPath, constants.F_OK)
  } catch {
    throw new Error(`No se encontro el archivo de esquema en ${schemaPath}`)
  }
}

const runMigration = async () => {
  await ensureSchemaExists()

  const sql = await readFile(schemaPath, 'utf-8')
  const trimmedSql = sql.trim()

  if (!trimmedSql) {
    throw new Error(`El archivo ${schemaPath} esta vacio`)
  }

  const clientConfig = process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false } // Requerido por Render
      }
    : {
        host: dbConfig.host,
        port: dbConfig.port,
        database: dbConfig.database,
        user: dbConfig.user,
        password: dbConfig.password,
        ssl: dbConfig.ssl,
      }

  const client = new Client(clientConfig)

  try {
    await client.connect()

    await client.query(trimmedSql)

    await client.query('ALTER TABLE Practica ADD COLUMN IF NOT EXISTS modalidad VARCHAR(50);')

    console.log(`Migracion ejecutada correctamente usando ${schemaPath}`)
  } finally {
    await client.end()
  }
}

runMigration().catch((error) => {
  console.error('Error al ejecutar la migracion:', error.message)
  process.exit(1)
})
