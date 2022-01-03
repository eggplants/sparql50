# SPARQL50

[SPARQL50本ノック](https://www.dlsite.com/home/work/=/product_id/RJ261278.html)の自分の解答

## 準備

- interface: <https://yasgui.triply.cc/>
- default endpoint: <https://ja.dbpedia.org/sparql>

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

- [NDLA](https://id.ndl.go.jp/auth/ndla/sparql)エンドポイントで検索する

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

## 中級

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
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX dbo: <http://dbpedia.org/ontology/>
select distinct ?p1 ?p2
where {
  ?w1
    dbo:starring ?p1;
    dbo:starring ?p2.
  ?w2
    dbo:starring ?p1;
    dbo:starring ?p2.
  ?w3
    dbo:starring ?p1;
    dbo:starring ?p2.
  ?w4
    dbo:starring ?p1;
    dbo:starring ?p2.
  ?p1
    dbp:production #|dbo:wikiPageWikiLink # too large
      dbr:ジャニーズ事務所;
    rdfs:label ?pl1.
  ?p2 rdfs:label ?pl2.

  filter (?w1 != ?w2)
  filter (?w1 != ?w3)
  filter (?w1 != ?w4)
  filter (?w2 != ?w3)
  filter (?w2 != ?w4)
  filter (?w3 != ?w4)
  filter (?p1 != ?p2)
}
```

### 37. ジャニタレと4回以上共演した人物(重複組削除)

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX dbo: <http://dbpedia.org/ontology/>
select distinct ?p1 ?p2 ?pp
where {
  ?w1
    dbo:starring ?p1;
    dbo:starring ?p2.
  ?w2
    dbo:starring ?p1;
    dbo:starring ?p2.
  ?w3
    dbo:starring ?p1;
    dbo:starring ?p2.
  ?w4
    dbo:starring ?p1;
    dbo:starring ?p2.
  ?p1
    dbp:production #|dbo:wikiPageWikiLink
      dbr:ジャニーズ事務所;
    rdfs:label ?pl1.
  ?p2 rdfs:label ?pl2.
  filter (?w1 != ?w2)
  filter (?w1 != ?w3)
  filter (?w1 != ?w4)
  filter (?w2 != ?w3)
  filter (?w2 != ?w4)
  filter (?w3 != ?w4)
  filter (?p1 != ?p2)
  bind(
    if(
      ?p1 < ?p2,
      concat(?pl1, "-", ?pl2),
      concat(?pl2, "-", ?pl1)
    ) as ?pp
  )
}
```

## 上級

### 38. 乱数 in Virtuoso

- `bif:rnd(lim, ...seed)` function -

```rq
PREFIX bif: <http://www.openlinksw.com/schemas/bif#>
select (bif:rnd(10, ?s, ?p, ?o) as ?rand)
where {
  ?x ?y ?z.
} limit 10
```

### 39. 秋葉原駅の路線とその降車駅を１つ乱択

```rq
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX bif: <http://www.openlinksw.com/schemas/bif#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
select ?line ?station
where {
  ?x
    dbp:駅番号 "TX01"@ja;
    dbo:servingRailwayLine ?line.
  ?line
    ^dbo:servingRailwayLine ?station.
  filter(?station != ?x)
}
order by (bif:rand(100, ?station, ?line))
limit 1
```

### 40. `dbr:Category::アニメ`の下位カテゴリパスの深さ

- 「アニメを上位カテゴリにもつカテゴリが持つ下位カテゴリの数の最大値」をカウントすれば良い

```rq
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
select (count(?c) as ?depth)
where {
  ?c
    skos:broader* dbr:Category:アニメ;
    ^skos:broader* ?child.
} group by ?child
limit 1
```

### 41. 日本の県境の山を県別集計

```rq
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX dbo: <http://dbpedia.org/ontology/>
select
  ?pref
  (count(?mount) as ?num)
  (group_concat(?mount;separator="|") as ?mounts)
where {
  ?x
    dc:subject dbr:Category:日本の都道府県;
    rdfs:label ?pref.
  filter contains(?prefs, str(?pref))
  {
    select
      ?mount
      (group_concat(?p; separator="|") as ?prefs)
    where {
      ?x
        dbo:wikiPageWikiLink dbr:Category:アジアの山;
        dbo:address ?p;
        rdfs:label ?mount.
      filter regex(?p, "^[亜-煕]+[都道府県]")
    }
    group by ?mount
    having (count(?p) > 1)
  }
}
group by ?pref
order by desc(?num)
```

### 42. 地名区分名である(`dbp:subdivisionType`)IRI(`dbp:〇〇名`)を作成して地名を列挙

- `IRI(str))` function - 文字列をIRIにする

```rq
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select distinct ?locProp ?name
where {
  ?x2 ?locProp ?name.
  {
    select distinct (IRI(?prop) as ?locProp)
    where {
      ?locType ^dbp:subdivisionType ?x1. # 地名区分の取得
      bind(
        concat(
          replace(str(?locType), "resource", "property"),
          "名"^^xsd:string
        ) as ?prop # dbp:〇〇名
      )
    }
  }
}
```

### 43. スポーツアニメ(`UNION`)

- 以下の2カテゴリを持つものを探す
　- `dbr:Portal:アニメ`
  - `dbp:Category:(|男子|女子){{ sports }}(アニメ|を題材としたアニメ作品)`

```rq
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
select ?anime ?category
where {
  ?x
    dbo:wikiPageWikiLink dbr:アニメ;
    dc:subject ?category;
    rdfs:label ?anime.
  {
    select ?category
    where {
      {
        ?x
          ^dbo:wikiPageWikiLink dbr:スポーツ競技一覧;
          rdfs:label ?sport.
        bind(IRI(
          concat(
            str(dbr:),
            "Category:"^^xsd:string,
            ?sport,
            "アニメ"^^xsd:string
          )
        ) as ?category)
      } union {
        ?x
          ^dbo:wikiPageWikiLink dbr:スポーツ競技一覧;
          rdfs:label ?sport.
        bind(IRI(
            concat(
              str(dbr:),
              "Category:"^^xsd:string,
              ?sport,
              "を題材としたアニメ作品"^^xsd:string)
        ) as ?category)
      } union {
        ?x
          ^dbo:wikiPageWikiLink dbr:スポーツ競技一覧;
          rdfs:label ?sport.
        bind(IRI(
            concat(
              str(dbr:),
              "Category:男子"^^xsd:string,
              ?sport,
              "アニメ"^^xsd:string)
        ) as ?category)
      } union {
        ?x
          ^dbo:wikiPageWikiLink dbr:スポーツ競技一覧;
          rdfs:label ?sport.
        bind(IRI(
            concat(
              str(dbr:),
              "Category:男子"^^xsd:string,
              ?sport,
              "を題材としたアニメ作品"^^xsd:string)
        ) as ?category)
      } union {
        ?x
          ^dbo:wikiPageWikiLink dbr:スポーツ競技一覧;
          rdfs:label ?sport.
        bind(IRI(
            concat(
              str(dbr:),
              "Category:女子"^^xsd:string,
              ?sport,
              "アニメ"^^xsd:string)
        ) as ?category)
      } union {
        ?x
          ^dbo:wikiPageWikiLink dbr:スポーツ競技一覧;
          rdfs:label ?sport.
        bind(IRI(
            concat(
              str(dbr:),
              "Category:女子"^^xsd:string,
              ?sport,
              "を題材としたアニメ作品"^^xsd:string)
        ) as ?category)
      }
    }
  }
}
```

### 44.  スポーツアニメのIRI

- IRI`dbp:Category:(男子|女子|){{ sports }}(アニメ|を題材とした(アニメ|)作品)`を楽に生成

```rq
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
select
  (IRI(
    concat(
      str(dbr:),
      "Category:"^^xsd:string,
      ?sex,
      ?sport,
      ?suffix
  )) as ?category)
where {
  ?x
    ^dbo:wikiPageWikiLink dbr:スポーツ競技一覧;
    rdfs:label ?sport.
  values ?sex {"" "男子" "女子"}
  values ?suffix {"アニメ" "を題材としたアニメ作品"}
}
```

### 45.  スポーツアニメ

```rq
# timeout
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dc: <http://purl.org/dc/terms/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
select ?anime ?category
where {
  ?y
    # dbo:wikiPageWikiLink dbr:アニメ;
    dc:subject ?category;
    rdfs:label ?anime.
  {
    select
      (IRI(
        concat(
          str(dbr:),
          "Category:"^^xsd:string,
          ?sex,
          ?sport,
          ?suffix
      )) as ?category)
    where {
      ?x
        dbp:wikiPageUsesTemplate dbr:Template:スポーツ一覧;
        rdfs:label ?sport.
      values ?sex {"" #"男子" "女子"
      }
      values ?suffix {"アニメ"# "を題材としたアニメ作品"
      }
    }
  }
}
```

## 職人級

### 46. Virtuoso情報

```rq
PREFIX bif: <http://www.openlinksw.com/schemas/bif#>
select
  (bif:sys_stat("st_dbms_name") as ?name)
  (bif:sys_stat("st_dbms_ver") as ?ver)
  (bif:sys_stat("st_build_date") as ?date)
  (bif:sys_stat("st_build_thread_model") as ?thread)
  (bif:sys_stat("st_build_opsys_id") as ?opsys)
where {
  ?s ?p ?o
} limit 1
```

### 47. FizzBuzz

```rq
PREFIX dbp: <http://ja.dbpedia.org/property/>
PREFIX dbr: <http://ja.dbpedia.org/resource/>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
select ?n ?out
where {
  ?x
    dbp:wikiPageUsesTemplate dbr:Template:自然数;
    rdfs:label ?i.
  bind(xsd:integer(?i) as ?n)
  filter(?n>0)
  bind(
    if(?n/15*15=?n, "FB",
      if(?n/5*5=?n, "B",
        if(?n/3*3=?n, "F", ?n))) as ?out)
} order by ?n
limit 100
```

### 48. 連番

- openlink virtuoso環境のみで動作
- `bif:sequence_set`を一回呼んで、`bif:sequence_next`でインクリメント

```rq
PREFIX bif: <http://www.openlinksw.com/schemas/bif#>
select
(bif:sequence_next("my_unique_key", 1, ?x, ?y, ?z) as ?id)
  ?c
where {
  ?x ?y ?z.
  bind(bif:sequence_set("my_unique_key", 1, 0) as ?c)
}
limit 100
```

### 49. クエリ置換

- openlink virtuoso環境のみで動作
- `bif:exec(sql, state, msg, params, maxrow, metadata, rows, cursor)`
- BDpediaでは:
  - `Virtuoso 37000 Error SP031:`
  - `exec() cannot be used in text of SPARQL query due to security restrictions`

```rq
PREFIX bif: <http://www.openlinksw.com/schemas/bif#>
select
  ?sparql ?sql ?exec
  ?state ?message
  (bif:length(?rows) as ?len)
  (bif:aref(bif:aref(?rows, 0), 0) as ?c0)
  (bif:aref(bif:aref(?rows, 0), 1) as ?l0)
  (bif:aref(bif:aref(?rows, 1), 0) as ?c1)
  (bif:aref(bif:aref(?rows, 1), 1) as ?l1)
  (bif:aref(bif:aref(?rows, 2), 0) as ?c2)
  (bif:aref(bif:aref(?rows, 2), 1) as ?l2)
where {
  ?x ?y ?z.
  bind(concat(
    'PREFIX skos: <http://www.w3.org/2004/02/skos/core#>\n',
    'PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n',
    'select * where {',
      '?c',
        'a skos:Concept;',
        'rdfs:label ?cl}'
    ) as ?sparql) # 実行するクエリ
  bind(str(bif:sparql_to_sql_text(?sparql)) as ?sql) # クエリをsqltextにしたもの
  bind("" as ?state) # 状態指定
  bind("no error" as ?message) # エラーメッセージの指定
  bind(bif:vector() as ?meta) # 返却されるメタ情報を格納する変数
  bind(bif:vector() as ?rows) # 返却されるデータを格納する変数
  bind(bif:exec( # クエリの実行
    ?sql, ?state, ?message,
    bif:vector(), 3, # 最大行数
    ?meta, ?rows)as ?exec
  )
}
```

### 50. Quine

- 実行結果がクエリ文

```rq
select ?s where {bind("select ?s where {bind('' as ?s)} limit 1" as ?s)} limit 1
```
