# SPARQL50

[SPARQL50本ノック](https://www.dlsite.com/home/work/=/product_id/RJ261278.html)の自分の解答

## 準備

- interface: https://yasgui.triply.cc/
- default endpoint: https://ja.dbpedia.org/sparql

## 初級

### 1. class IRIの取得

- 関係`a`は`is-a`関係、`rdf:type`と等価

```rq
select distinct ?c {
  ?e a ?c.
}
```

### 2. Graph IRIの取得

- `GRAPH` clause - graph IRIの取得

```rq
select distinct ?g {
  graph ?g {
    ?x ?y ?z.
  }
}
```

### 3. 解存在判定

- `ASK` clause -  解存在判定、`t`/`f`のboolが返る(`IF`とかで利用)

```rq
PREFIX prop: <http://ja.dbpedia.org/property/>
ask {
  prop:ja ?y ?z.
}
```

### 4. ペタンクをラベルに持つリソースに関連するトリプルを取得

- `DISCRIBE` clause - URIの関連データをトリプルで取得, 実装によって返るデータ形式が異なる

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
describe ?x where {
  ?x rdfs:label "ペタンク"@ja.
}
```

### 5. 特定の日時の間に生まれた人物を取得

- `FILTER(bool)` function - 指定した条件でリソースを絞り込み

```rq
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
select ?s
where {
  ?s dbp:生年 ?birthDate .
  filter(
    "1950-01-01"^^xsd:date < ?birthDate &&
    ?birthDate < "1959-12-31"^^xsd:date
  )
}
```

### 6. リテラルの言語タグ一覧取得

- `LANG(literal)` function - リテラルの言語タグ

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select distinct ?ltag {
  ?s rdfs:label ?label.
  bind(lang(?label) as ?ltag)
}
```

### 7. 家紋の名称IRIが存在している時IRIのbasenameを、そうでなければそのまま返したい

- `IF(bool, true-v, false-v)` function - 条件分岐
- `ISIRI(resource)` function - IRIかそうでないリソースか判定
- `STRAFTER(str, offset-str)` function - 特定文字列の後ろ文字列を取得
- `STR(any)` function - 文字列リテラルへのキャスト

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
select distinct ?name (if(
  isIRI(?kamon),
  strafter(str(?kamon), "resource/"),
  str(?kamon))
  as ?kamonName)
where {
  ?entry
    rdfs:label ?name;
    dbp:家紋名称 ?kamon.
}
```

### 8. 家紋の名称IRIが存在している時IRIのbasenameを、そうでなければそのまま返したい(`BIND`)

- `BIND(literal as val)` function - 変数束縛

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
select distinct ?name ?kamonName
where {
  ?entry
    rdfs:label ?name;
    dbp:家紋名称 ?kamon.
  bind (
    if(isIRI(?kamon),
       strafter(str(?kamon), "resource/"),
       str(?kamon))
    as ?kamonName)
}
```

### 9. 家紋の名称IRIが存在している時IRIのbasenameを、そうでなければそのまま返したい(`REPLACE`)

- `REPLACE(literal, pattern, replace-v)` function - regexパターン置換

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
select distinct ?name ?kamonName
where {
  ?entry
    rdfs:label ?name;
    dbp:家紋名称 ?kamon.
  bind (
    if(isIRI(?kamon),
       replace(
         str(?kamon), "^.+/resource/([^/]+)/?$", "$1"
       ),
       str(?kamon))
    as ?kamonName)
}
```

### 10. `rdfs:label`属性のリテラルが`/QL$/i`のものを抽出

- `REGEX(literal, pattern, sed-like-flag)` function - regexマッチ

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select ?x ?label
where {
  ?x rdfs:label ?label.
  filter regex(?label, "QL$", "i")
}
```

### 11. カテゴリ

- `CONTAINS(str, contained-str)` function - 特定部分文字列が含まれているか判定 

```rq
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select distinct ?cat
where {
  ?x a skos:Concept.
  filter contains(str(?x), "resource/Category:")
  bind(
    strafter(str(?x), "y:") as ?cat
  )
}
```

### 12. 記事名と同名のカテゴリが存在する記事

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select distinct ?name
where {
  ?x rdfs:label ?labelx.
  ?cat
    a skos:Concept;
    rdfs:label ?labelcat.
  filter contains(str(?cat), "resource/Category:")
  filter (?x != ?cat)
  filter (?labelx = ?labelcat)
  bind(
    strafter(str(?x), "resource/")
    as ?name
  )
}
```

### 13. 都道府県

- `dc:subject`: 件名
- `ORDER BY` clause: 順
  - `ORDER BY ASC(key)`
  - `ORDER BY DESC(key)`

```rq
PREFIX dc: <http:/purl.org/dc/terms/>
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select ?code ?pref
where {
  ?pref
    dc:subject dbr:Category:日本の都道府県;
    dbp:区分 ?category;
    dbo:areaCode ?code.
  filter regex(?category, "[都道府県]$")
  filter contains(?code, "JP")
} order by ?code
```

### 14. バレーボールのアニメ

- `resource IN (...cand)` operator - 複数候補に一致するものがあるか判定

```rq
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select distinct ?name
where {
  ?anime dc:subject ?cat.
  filter (
    ?cat in
    (
      dbr:Category:バレーボールを題材とした作品,
      dbr:Category:女子バレーボールを題材とした作品,
      dbr:Category:バレーボール漫画
    )
  )
  bind(
    strafter(str(?anime), "resource/")
    as ?name
  )
} order by ?name
```

### 15. プログラミング言語

```rq
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select distinct ?pllabel
where {
  ?pl
    a dbo:ProgrammingLanguage;
    rdfs:label ?pllabel
} order by ?pllabel
```

### 16. プログラミング言語のイニシャル別数集計

- `GROUP BY` clause - 集約
- `COUNT(key)` function - keyの個数をカウント

```rq
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select
  ?init
  (count(?pl) as ?num)
  (group_concat(?pllabel; separator="|") as ?langs)
where {
  ?pl
    a dbo:ProgrammingLanguage;
    rdfs:label ?pllabel.
  bind (
    substr(?pllabel, 1, 1)
    as ?init
  )
} group by ?init order by desc(?num)
```

### 17. 同属性をn以上持つもの

`HAVING` clause - Groupに対する`FILTER`

```rq
select ?y (count(?y)) as ?num)
where {
  ?x a ?y
}
group by ?y
having (14 <= count(?y))
order by desc(count(?y))
```

### 18. 今日誕生日の人物

- `NOW()` function - `xsd:dateTime`の今
- `MONTH(datetime)` function - 月をintで抽出
- `DAY(datetime)` function - 日をintで抽出

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
select ?xlabel
where {
  ?x
    dbp:生月 ?birthMonth;
    dbp:生日 ?birthDay;
    rdfs:label ?xlabel.
  filter(
      month(now()) = ?birthMonth &&
      day(now()) = ?birthDay
  )
}
```

### 19. 東京都出身 && 50歳以下 && 俳優

- DATATYPE(resource)` function - 型取得

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX dbp: <http://ja.dbpedia.org/property/>
select ?name
where {
  ?actor
    dc:subject dbr:Category:東京都出身の人物;
    dbp:職業 dbr:俳優;
    dbp:生年 ?year;
    rdfs:label ?name.
  filter (
    datatype(?year) = xsd:integer && # 生年->`不詳`があるので排除
    year(now()) - ?year <= 50
  )
}
```

### 20. 声優

#### DBpedia

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select ?name
where {
  ?actor
    dc:subject ?s;
    rdfs:label ?name.
  filter (
    ?s in (
      dbr:Category:日本の男性声優,
      dbr:Category:日本の女性声優
    )
  )
}
```

#### [NDLA](https://id.ndl.go.jp/auth/ndla/sparql)

```rq
PREFIX rda: <http://RDVocab.info/ElementsGr2/>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
select ?name
where {
  ?concept foaf:primaryTopic ?topic. # 典拠
  ?topic
    a foaf:Person;
    foaf:name ?name; # 名称
    rda:biographicalInformation ?work.
  filter contains(?work, "声優")
}
```

### 21. 山一覧ページからリンクされているページを調べる

- `^<URI>`(InversePath) - `parent <-[attr]- child`

```rq
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select ?x
where {
  ?x ^dbo:wikiPageWikiLink dbr:日本の山一覧.
  # dbr:日本の山一覧 dbo:wikiPageWikiLink ?x.
}
```

### 22. 乱数 sample n=10

- `RAND()` function - `0<=n<1`の乱数

```rq
select (rand() as ?a)
where {
  ?x ?y ?z.
} limit 10
```

##  中級

### 23. DBpediaで上位カテゴリをもたないカテゴリ

- `NOT EXISTS` clause - 解を持たないマッチングかどうか判定

```rq
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select distinct ?name
where {
  ?c
    a skos:Concept.
  filter not exists {
    ?c skos:broader ?bc
  }
  filter contains(str(?c), "dbpedia.org/resource/Category:")
  bind(strafter(str(?c), "Category:")as ?name)
}
```

### 24. クラスIRIローカルリスト

- 時間かかる

```rq
select distinct
  ?prefix
  (count(distinct(?class)) as ?num)
  (group_concat(distinct ?class;SEPARATOR="|") as ?classes)
where {
  ?x a ?y.
  bind(
    "^(.+[^a-zA-Z_0-9-])([a-zA-Z_0-9-]*)$" as ?p
  )
  bind(
    replace(str(?y), ?p, "$1") as ?prefix
  )
  bind(
    replace(str(?y), ?p, "$2") as ?class
  )
}
group by ?prefix
order by desc(count(distinct(?class)))
```

### 25. 同属性をn以上持つもの(サブクエリ)

```rq
select ?y ?num
where {
  bind(14 as ?n)
  filter(?n <= ?num)
  {
    select ?y (count(?y) as ?num)
    where {
      ?x a ?y.
    } group by ?y
  }
} order by desc(?num)
```

### 26. 都道府県別金メダリスト数

```rq
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select
  ?pref
  (count(?pref) as ?num)
  (group_concat(?x; separator="|") as ?medalists)
where {
  ?x
    dc:subject dbr:Category:日本のオリンピック金メダリスト;
    dc:subject ?y;
    rdfs:label ?name.
  ?y rdfs:label ?p.
  filter regex(?p, "[都道府県]出身の人物")
  bind(replace(?p, "(.*)出身の人物$", "$1") as ?pref)
}
group by ?pref
order by desc(?num)
```

### 27. 日本姓ランキング

- `STRLEN(str)` - 文字列長

```rq
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select ?family (count(?family) as ?num)
where {
  ?x
    a dbo:Person;
    dbo:nationality dbr:日本;
    dbo:abstract ?abst.
  bind(
    replace(?abst, "^([^ ]+).*", "$1")
    as ?family
  )
  filter(
    0 < strlen(?family) && strlen(?family) < 10
  )
}
group by ?family
order by desc(?num)
```

### 28. 世界遺産

```rq
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select ?name ?country
where {
  ?x
    dc:subject ?y;
    rdfs:label ?name;
    dbp:country ?country.
  ?y  skos:broader dbr:Category:五十音順の世界遺産. 
}
```

### 29. 借用語

```rq
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select
  ?category
  (count(?word) as ?num)
  (group_concat(?word; separator="|") as ?words)
where {
  ?x
    dc:subject ?y;
    rdfs:label ?word.
  ?y
    skos:broader dbr:Category:借用語;
    rdfs:label ?category.
  filter contains(?category, "からの借用語")
} group by ?category order by desc(?num)
```

### 30. 政党とイデオロギー

```rq
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
select
  ?name
  (count(distinct ?ideorogy) as ?num)
  (group_concat(distinct ?ideorogy; separator="|") as ?ideorogies)
where {
  ?x
    dbp:ideology|dbo:政治的思想・立場 ?y;
    rdfs:label ?name.
  ?y rdfs:label ?ideorogy.
} order by desc(?num)
```

### 31. 日本の県境の山

```rq
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select
  distinct ?name
  (count(?pref) as ?num)
  (group_concat(?pref; separator="|") as ?prefs)
where {
  ?x
    ^dbo:wikiPageWikiLink dbr:日本の山一覧;
    rdfs:label ?name;
    dc:subject ?y.
  ?y rdfs:label ?p.
  filter regex(?p, "^.*[都道府県]の.*山$")
  bind(strbefore(?p,"の山") as ?pref)
} order by desc(?num)
```

### 32. `rdf:list`の各要素をバラして取得

```rq
PREFIX ex: <http://example.org/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
select ?e
where {
  ?list ex:member/rdf:rest*/rdf:first ?e.
}
```

### 33. `rdf:list`の特定インデックスの要素を取得

- `rdf:rest{ind}` - 指定位置の要素を取得(非標準)

```rq
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX ex: <http://example.org/>
select *
where {
  ?s ex:member/rdf:rest{2}/rdf:first ?o.
}
```

### 34. `dbr:Category:アニメ`の下位カテゴリ

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select distinct ?category
where {
 ?x
   skos:broader+ dbr:Category:アニメ;
   rdfs:label ?category.
}
```

### 35. 複数のグラフをマージしたグラフに対して問い合わせを行う

- `from` clauseが宣言されていない場合は暗黙的に宣言される
  - デフォルトグラフ(Fuseki)
  - 全てマージされたグラフ(virtuoso)

```rq
select ?x ?y
from <http://example.org/foo>
from <http://example.org/bar>
from <http://example.org/baz>
where {
  ?x <http://example.org/term> ?y.
}
```

### 36. ジャニタレと4回以上共演した人物(重複組許容)

```rq
```

### 37. ジャニタレと4回以上共演した人物(重複組削除)

```rq

```

## 上級

### 38. 乱数 in Virtuoso

- `bif:rnd(lim, ...seed)` function 

```rq

```

### 39. 秋葉原駅の路線とその降車駅を１つ乱択

```rq

```

### 40. パスの深さ

```rq

```

### 41. 日本の県境の山 group by pref

```rq

```

### 42. 地名を目的語に持つIRI動的生成

```rq

```

### 43. スポーツアニメ(`UNION`)

```rq

```

### 44.  スポーツアニメとそのIRI

```rq

```

### 45.  スポーツアニメ(`UNION`なし)

```rq

```

## 職人級

### 46. Virtuoso情報

```rq

```

### 47. FizzBuzz

```rq

```

### 48. 連番

```rq

```

### 49. クエリ置換

```rq

```

### 50. Quine

```rq

```
