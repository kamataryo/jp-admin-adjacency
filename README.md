# jp-admin-adjacency

## PostGIS 起動

```shell
$ docker build -t postgis .
$ docker run --name postgis -e POSTGRES_PASSWORD=postgis -d -p 5432:5432 -v $(pwd)/data:/root/data postgis
$ docker exec -it postgis psql -U postgres -c "SELECT PostGIS_Version();"
```

## 国土数値情報ダウンロード・変換・インポート

```shell
$ curl -sL https://nlftp.mlit.go.jp/ksj/gml/data/N03/N03-2023/N03-20230101_GML.zip > ./data/admin.zip
$ unzip ./data/admin.zip -d ./data
$ ogr2ogr -t_srs EPSG:4326 -oo ENCODING=shift_jis -nln admin -f PostgreSQL PG:"dbname=postgres user=postgres password=postgis host=localhost port=5432" ./data/N03-23_230101.shp
```

### スキーマ確認

```shell
$ docker exec -it postgis psql -U postgres
```

```sql
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'admin';
```

```shell
 column_name  |     data_type     
--------------+-------------------
 ogc_fid      | integer
 objectid     | double precision
 n03_001      | character varying
 n03_002      | character varying
 n03_004      | character varying
 n03_004      | character varying
 n03_007      | character varying
 shape_leng   | numeric
 shape_area   | numeric
 wkb_geometry | USER-DEFINED
```

### トポロジー生成

```sql
SELECT CreateTopology('admin-topo', 4326); -- トポロジスキーマの生成
SELECT topology.AddTopoGeometryColumn('admin-topo', 'public', 'admin', 'topogeom', 'POLYGON'); -- トポロジレイヤの追加
UPDATE admin SET topogeom = topology.toTopoGeom(wkb_geometry, 'admin-topo', 1, 1.0); -- 既存のジオメトリデータをトポロジに変換
```

### グラフデータ生成

```sql
root@{container_id}:/# psql -U postgres -c "SELECT row_to_json(t) FROM (
  SELECT
    a.n03_004 AS name,
    a.n03_007 AS code,
    ARRAY_AGG(DISTINCT b.n03_004) FILTER (WHERE a.n03_007 != b.n03_007) AS neighbor_names,
    ARRAY_AGG(DISTINCT b.n03_007) FILTER (WHERE a.n03_007 != b.n03_007) AS neighbor_codes,
    ST_AsGeoJSON(
        ST_Centroid(
            (SELECT wkb_geometry FROM admin WHERE n03_007 = a.n03_007 ORDER BY ST_Area(wkb_geometry) DESC LIMIT 1)
        )
    ) AS center
  FROM
      admin a
  JOIN
      admin b ON ST_Touches(a.wkb_geometry, b.wkb_geometry) OR ST_Intersects(a.wkb_geometry, b.wkb_geometry)
  GROUP BY
    a.n03_004, a.n03_007
) t;" -t > ~/data/out.jsons
```

```shell
$ mv ./data/out.jsons ./docs/out.jsons
```
