# GIS Antananarivo

## Fichier inclus

| Fichier | Rôle |
|---|---|
| `antananarivo_roads.shp` (+ `.shx`, `.dbf`, `.prj`, `.cpg`) | **1136 routes** OSM (centre d’Antananarivo) |
| `ATTRIBUTION.txt` | Licence ODbL / sources |

- **CRS** : WGS84 (EPSG:4326)  
- **BBox** : lon ≈ 47.51–47.56, lat ≈ −18.94–−18.88  
- **Source** : OpenStreetMap via Overpass API, converti en shapefile ESRI  
- **Licence** : © OpenStreetMap contributors — [ODbL](https://www.openstreetmap.org/copyright)

## Dans Laoka Lab

- Paramètre UI **`Utiliser GIS OSM`** (défaut ON)  
- Les agents `route` sont créés depuis le shapefile  
- Magasins / salles / foyers placés en coordonnées WGS84 (quartiers réels)  
- Si GIS OFF → carte abstraite 100×100 + quartiers stylisés

## Mettre à jour / élargir

1. Re-télécharger un extrait Overpass (ou Geofabrik Madagascar découpé)  
2. Remplacer `antananarivo_roads.*`  
3. Relancer `LaokaLab.gaml`

Geofabrik national (lourd) : https://download.geofabrik.de/africa/madagascar.html  
