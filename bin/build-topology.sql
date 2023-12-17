-- トポロジスキーマの生成
SELECT CreateTopology('admin-topo', 4326);
 -- トポロジレイヤの追加
SELECT topology.AddTopoGeometryColumn('admin-topo', 'public', 'admin', 'topogeom', 'POLYGON');
-- 既存のジオメトリデータをトポロジに変換
UPDATE admin SET topogeom = topology.toTopoGeom(wkb_geometry, 'admin-topo', 1, 1.0);
