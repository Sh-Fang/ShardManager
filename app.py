#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import sqlite3
import os
from datetime import datetime
from contextlib import contextmanager

app = Flask(__name__, static_folder='.')
CORS(app)

# 数据库文件路径
DB_PATH = os.environ.get('DB_PATH', '/data/shardmanager.db')

# 确保数据目录存在
os.makedirs(os.path.dirname(DB_PATH) if os.path.dirname(DB_PATH) else '.', exist_ok=True)


@contextmanager
def get_db():
    """获取数据库连接的上下文管理器"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def init_db():
    """初始化数据库"""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                hash_code INTEGER NOT NULL,
                mysql_prefix TEXT,
                mysql_shard_count INTEGER,
                mysql_shard_index INTEGER,
                mysql_table_name TEXT,
                mongo_prefix TEXT,
                mongo_shard_count INTEGER,
                mongo_shard_index INTEGER,
                mongo_table_name TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # 创建索引以提高查询性能
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_created_at ON history(created_at DESC)
        ''')
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_user_id ON history(user_id)
        ''')
        
        conn.commit()


@app.route('/')
def index():
    """返回主页"""
    return send_from_directory('.', 'index.html')


@app.route('/api/history', methods=['GET'])
def get_history():
    """获取历史记录列表"""
    limit = request.args.get('limit', 100, type=int)
    
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT * FROM history 
            ORDER BY created_at DESC 
            LIMIT ?
        ''', (limit,))
        
        rows = cursor.fetchall()
        history = [dict(row) for row in rows]
        
    return jsonify(history)


@app.route('/api/history', methods=['POST'])
def create_history():
    """创建新的历史记录"""
    data = request.get_json()
    
    if not data or 'user_id' not in data:
        return jsonify({'error': '缺少必要参数 user_id'}), 400
    
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO history (
                user_id, hash_code, 
                mysql_prefix, mysql_shard_count, mysql_shard_index, mysql_table_name,
                mongo_prefix, mongo_shard_count, mongo_shard_index, mongo_table_name
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            data['user_id'],
            data['hash_code'],
            data.get('mysql_prefix'),
            data.get('mysql_shard_count'),
            data.get('mysql_shard_index'),
            data.get('mysql_table_name'),
            data.get('mongo_prefix'),
            data.get('mongo_shard_count'),
            data.get('mongo_shard_index'),
            data.get('mongo_table_name')
        ))
        conn.commit()
        
        record_id = cursor.lastrowid
    
    return jsonify({'id': record_id, 'message': '保存成功'}), 201


@app.route('/api/history/<int:record_id>', methods=['DELETE'])
def delete_history(record_id):
    """删除指定的历史记录"""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute('DELETE FROM history WHERE id = ?', (record_id,))
        conn.commit()
        
        if cursor.rowcount == 0:
            return jsonify({'error': '记录不存在'}), 404
    
    return jsonify({'message': '删除成功'})


@app.route('/api/history/clear', methods=['DELETE'])
def clear_history():
    """清空所有历史记录"""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute('DELETE FROM history')
        conn.commit()
        deleted_count = cursor.rowcount
    
    return jsonify({'message': f'已清空 {deleted_count} 条历史记录'})


@app.route('/api/health', methods=['GET'])
def health_check():
    """健康检查接口"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    })


if __name__ == '__main__':
    init_db()
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)

