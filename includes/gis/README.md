# GIS Antananarivo (optionnel)

Laoka Lab fonctionne **sans** carte GIS réelle (quartier abstrait 100×100).

## Pourquoi ce n’est pas inclus par défaut

- Aucun shapefile / GeoJSON n’est fourni dans le dépôt.
- Le cœur scientifique = arbitrage de contraintes repas, pas la mobilité urbaine.
- Une carte réelle ajoute des dépendances (projection, chemins, données OpenStreetMap…).

## Comment l’ajouter plus tard

1. Exporter un quartier d’Antananarivo (routes / bâtiments) en shapefile ou geojson.
2. Placer les fichiers ici, ex. :
   - `includes/gis/antanana_routes.shp` (+ `.dbf`, `.shx`, `.prj`)
3. Dans `InitMonde.gaml`, charger via GAMA :
   - `shape_file` / `file` + `create` d’agents sur les géométries
4. Repositionner magasins / salles / foyers sur ce fond.

## En attendant

Le graphe `as_distance_graph` actuel suffit pour démontrer la **logistique** (magasin / salle les plus proches).
