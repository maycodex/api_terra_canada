// Script de prueba de conexión a base de datos
import pool, { query } from './src/config/database';

async function testConnection() {
  try {
    console.log('🔍 Probando conexión a PostgreSQL...\n');
    
    // Test 1: Conexión básica
    const client = await pool.connect();
    console.log('✅ Test 1: Conexión establecida exitosamente');
    client.release();
    
    // Test 2: Query simple
    const result = await query('SELECT NOW() as current_time');
    console.log('✅ Test 2: Query ejecutada:', result.rows[0].current_time);
    
    // Test 3: Verificar tablas
    const tables = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    console.log(`✅ Test 3: Encontradas ${tables.rowCount} tablas:`);
    tables.rows.forEach((row, i) => {
      console.log(`   ${i + 1}. ${row.table_name}`);
    });
    
    // Test 4: Contar usuarios
    const usuarios = await query('SELECT COUNT(*) as total FROM usuarios');
    console.log(`✅ Test 4: Total de usuarios: ${usuarios.rows[0].total}`);
    
    // Test 5: Contar roles
    const roles = await query('SELECT * FROM roles ORDER BY id');
    console.log(`✅ Test 5: Roles disponibles:`);
    roles.rows.forEach(rol => {
      console.log(`   - ${rol.nombre} (ID: ${rol.id})`);
    });
    
    console.log('\n🎉 Todas las pruebas pasaron exitosamente!\n');
    
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error en las pruebas:', error);
    process.exit(1);
  }
}

testConnection();
