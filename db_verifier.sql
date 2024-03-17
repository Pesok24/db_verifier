WITH
    -- configure
    conf AS (
        SELECT
            'ru'  AS conf_language_code,     -- null or value like 'en', 'ru' (see check_description)
            true  AS enable_check_no1001,    -- [error] check no unique key
            true  AS enable_check_no1002,    -- [error] check no primary key constraint
            true  AS enable_check_fk1001,    -- [error] check fk uses mismatched types
            false AS enable_check_fk1002,    -- [warning] check fk uses nullable columns
            false AS enable_check_fk1007,    -- [notice] not involved in foreign keys
            true  AS enable_check_c1001,     -- [warning] constraint not validated
            true  AS enable_check_i1001,     -- [warning] similar indexes
            true  AS enable_check_i1002,     -- [error] index has bad signs
            true  AS enable_check_i1003,     -- [warning] similar indexes unique and not unique
            false AS enable_check_i1005,     -- [notice] similar indexes (roughly)
            true  AS enable_check_i1010,     -- [notice] b-tree index for array column
            true  AS enable_check_s1010,     -- [critical] less 5% unused sequence values
            true  AS enable_check_s1011,     -- [error] less 10% unused sequence values
            true  AS enable_check_s1012,     -- [warning] less 20% unused sequence values
            true  AS enable_check_n1001,     -- [warning] confusion in name of schemas
            true  AS enable_check_n1005      -- [warning] confusion in name of relation attributes
    ),
    --
    check_level_list AS (
        SELECT
            check_level
        FROM
            (VALUES
                ('critical'),
                ('error'),
                ('warning'),
                ('notice')
            ) AS t(check_level)
    ),
    --
    object_type_list AS (
        SELECT
            object_type
        FROM
            (VALUES
                ('attribute'),
                ('constraint'),
                ('index'),
                ('relation'),
                ('schema'),
                ('sequence')
            ) AS t(object_type)
    ),
    -- checks based on system catalog info
    check_based_on_system_catalog AS (
        SELECT
            t.check_code,
            t.parent_check_code,
            t.check_name,
            t.check_level,
            t.object_type,
            'system catalog' AS check_source_name
        FROM
            (VALUES
                ('no1001',     null, 'no unique key', 'error', 'relation'),
                ('no1002', 'no1001', 'no primary key constraint', 'error', 'relation'),
                ('fk1001',     null, 'fk uses mismatched types', 'error', 'constraint'),
                ('fk1002',     null, 'fk uses nullable columns', 'warning', 'constraint'),
                ('fk1007',     null, 'not involved in foreign keys', 'notice', 'relation'),
                ('c1001',      null, 'constraint not validated', 'warning', 'constraint'),
                ('i1001',      null, 'similar indexes', 'warning', 'index'),
                ('i1002',      null, 'index has bad signs', 'error', 'index'),
                ('i1003',      null, 'similar indexes unique and not unique', 'warning', 'index'),
                ('i1005',      null, 'similar indexes (roughly)', 'notice', 'index'),
                ('i1010',      null, 'b-tree index for array column', 'notice', 'index'),
                ('s1010',      null, 'less 5% unused sequence values', 'critical', 'sequence'),
                ('s1011',   's1010', 'less 10% unused sequence values', 'error', 'sequence'),
                ('s1012',   's1011', 'less 20% unused sequence values', 'warning', 'sequence'),
                ('n1001',      null, 'confusion in name of schemas', 'warning', 'schema'),
                ('n1005',      null, 'confusion in name of relation attributes', 'warning', 'attribute')
            ) AS t(check_code, parent_check_code, check_name, check_level, object_type)
            INNER JOIN check_level_list AS cll ON cll.check_level = t.check_level
            INNER JOIN object_type_list AS otl ON otl.object_type = t.object_type
    ),
    -- description for checks
    check_description AS (
        SELECT
            ROW_NUMBER() OVER (PARTITION BY description_check_code ORDER BY description_language_code ASC NULLS LAST)
                AS description_check_code_row_num,
            *
        FROM
            (VALUES
                ('no1001', null, 'Relation has no unique key.'),
                ('no1001', 'ru', 'У отношения нет уникального ключа (набора полей). Это может создавать проблемы при удалении записей, при логической репликации и др.'),
                ('no1002', null, 'Relation has no primary key constraint.'),
                ('no1002', 'ru', 'У отношения нет ограничения primary key.'),
                ('fk1001', null, 'Foreign key uses columns with mismatched types.'),
                ('fk1001', 'ru', 'Внешний ключ использует колонки с несовпадающими типами.'),
                ('fk1002', null, 'Foreign key uses nullable columns.'),
                ('fk1002', 'ru', 'Внешний ключ использует колонки, допускающие значение NULL.'),
                ('fk1007', null, 'Relation is not involved in foreign keys.'),
                ('fk1007', 'ru', 'Отношение не используется во внешних ключах (возможно оно больше не нужно).'),
                ('c1001',  null, 'Constraint was not validated for all data.'),
                ('c1001',  'ru', 'Ограничение не проверено для всех данных (возможно присутствуют записи, нарушающие ограничение).'),
                ('i1001',  null, 'Indexes are very similar.'),
                ('i1001',  'ru', 'Индексы очень похожи (возможно совпадают).'),
                ('i1002',  null, 'Index has bad signs.'),
                ('i1002',  'ru', 'Индекс имеет признаки проблем.'),
                ('i1003',  null, 'Unique and not unique indexes are very similar.'),
                ('i1003',  'ru', 'Уникальный и не уникальный индексы очень похожи (возможно не уникальный лишний).'),
                ('i1005',  null, 'Indexes are roughly similar.'),
                ('i1005',  'ru', 'Индексы похожи по набору полей (грубое сравнение).'),
                ('i1010',  null, 'B-tree index for array column.'),
                ('i1010',  'ru', 'B-tree индекс на поле с массивом значений, не индексирует элементы массива (возможно нужен GIN индекс).'),
                ('s1010',  null, 'The sequence has less than 5% unused values left.'),
                ('s1010',  'ru', 'У последовательности осталось менее 5% неиспользованных значений.'),
                ('s1011',  null, 'The sequence has less than 10% unused values left.'),
                ('s1011',  'ru', 'У последовательности осталось менее 10% неиспользованных значений.'),
                ('s1012',  null, 'The sequence has less than 20% unused values left.'),
                ('s1012',  'ru', 'У последовательности осталось менее 20% неиспользованных значений.'),
                ('n1001',  null, 'There may be confusion in the name of the schemas. The names are dangerously similar.'),
                ('n1001',  'ru', 'Возможна путаница в наименованиях схем. Наименования опасно похожи.'),
                ('n1005',  null, 'There may be confusion in the name of the relation attributes. The names are dangerously similar.'),
                ('n1005',  'ru', 'Возможна путаница в наименованиях атрибутов отношения (колонок). Наименования опасно похожи.')
            ) AS t(description_check_code, description_language_code, description_value)
        WHERE
            description_language_code IS NULL
            OR description_language_code IN (SELECT conf_language_code FROM conf)
    ),
    -- all checks with descriptions
    check_list AS (
        SELECT
            check_based_on_system_catalog.*,
            description_language_code,
            description_value
        FROM check_based_on_system_catalog
            LEFT JOIN check_description ON check_code = description_check_code AND description_check_code_row_num = 1
    ),
    --
    excluded_schema_list AS (
        SELECT
            oid
        FROM pg_catalog.pg_namespace
        WHERE
            (
                -- exclude system schemas
                nspname IN ('information_schema')
                -- postgresql specific
                OR nspname IN ('pg_catalog')
                OR nspname LIKE 'pg_toast%'
            )
    ),
    --
    filtered_schema_list AS (
        SELECT
            n.*,
            format('%I', n.nspname) AS formatted_schema_name
        FROM pg_catalog.pg_namespace AS n
        WHERE n.oid NOT IN (SELECT oid FROM excluded_schema_list)
    ),
    --
    filtered_class_list AS (
        SELECT
            c.*,
            concat(n.nspname, '.',  c.relname) AS class_name,
            concat(n.formatted_schema_name, '.',  format('%I', c.relname)) AS formatted_class_name
        FROM pg_catalog.pg_class AS c
            INNER JOIN filtered_schema_list AS n ON c.relnamespace = n.oid
    ),
    -- no1001 - no unique key
    check_no1001 AS (
        SELECT
            t.oid AS object_id,
            t.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', t.oid,
                'object_name', t.class_name,
                'object_type', ch.object_type,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_class_list AS t
            LEFT JOIN check_list ch ON ch.check_code = 'no1001'
        WHERE
            (SELECT enable_check_no1001 FROM conf)
            AND t.relkind IN ('r', 'p')
            -- no constraint PK [test - public.no1001_1]
            AND NOT EXISTS (SELECT * FROM pg_catalog.pg_constraint AS c
                WHERE t.oid = c.conrelid AND t.relnamespace = c.connamespace AND c.contype IN ('p')
                )
            -- no constraint UNIQUE with all not nullable columns [test - public.no1001_2]
            AND NOT EXISTS (SELECT * FROM pg_catalog.pg_constraint AS c
                WHERE t.oid = c.conrelid AND t.relnamespace = c.connamespace AND c.contype IN ('u')
                    AND NOT EXISTS (SELECT * FROM pg_catalog.pg_attribute AS a
                        WHERE a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey) AND NOT a.attnotnull)
                )
            -- unique index with all not nullable columns and not partial [test - public.no1001_4]
            AND NOT EXISTS (SELECT * FROM pg_catalog.pg_index AS i
                WHERE t.oid = i.indrelid AND i.indisunique AND (i.indpred IS NULL)
                    AND NOT EXISTS (SELECT * FROM pg_catalog.pg_attribute AS a
                        WHERE a.attrelid = i.indrelid AND NOT a.attnotnull
                            AND a.attnum = ANY ((string_to_array(indkey::text, ' ')::int2[])[1:indnkeyatts]))
                )
            -- UNIQUE NULLS NOT DISTINCT
            -- (used `pg_catalog.pg_index.indnullsnotdistinct`, see https://www.postgresql.org/docs/15/release-15.html)
            AND CASE
                WHEN (SELECT current_setting('server_version_num')::integer < 150000) THEN true
                ELSE
                    -- unique index with NULLS NOT DISTINCT and not partial [test - public.no1001_8]
                    NOT EXISTS (SELECT * FROM pg_catalog.pg_index AS i
                        WHERE t.oid = i.indrelid AND i.indisunique AND (i.indpred IS NULL)
                            -- for support PostgreSQL 12..14
                            AND COALESCE((to_jsonb(i.*) -> 'indnullsnotdistinct')::boolean, false))
                    -- no constraint UNIQUE with NULLS NOT DISTINCT [test - public.no1001_7]
                    AND NOT EXISTS (SELECT * FROM pg_catalog.pg_constraint AS c
                        WHERE t.oid = c.conrelid AND t.relnamespace = c.connamespace AND c.contype IN ('u')
                            AND EXISTS (SELECT * FROM pg_catalog.pg_index AS i
                                WHERE i.indexrelid = c.conindid
                                    -- for support PostgreSQL 12..14
                                    AND COALESCE((to_jsonb(i.*) -> 'indnullsnotdistinct')::boolean, false))
                        )
                END
    ),
    -- no1002 - no primary key constraint
    check_no1002 AS (
        SELECT
            t.oid AS object_id,
            t.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', t.oid,
                'object_name', t.class_name,
                'object_type', ch.object_type,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_class_list AS t
            LEFT JOIN check_list ch ON ch.check_code = 'no1002'
        WHERE
            (SELECT enable_check_no1002 FROM conf)
            -- not in parent check
            AND NOT ((SELECT enable_check_no1001 FROM conf) AND (t.oid IN (SELECT object_id FROM check_no1001)))
            AND t.relkind IN ('r', 'p')
            -- no constraint PK
            AND NOT EXISTS (SELECT * FROM pg_catalog.pg_constraint AS c
                WHERE t.oid = c.conrelid AND t.relnamespace = c.connamespace AND c.contype IN ('p')
                )
    ),
    -- filtered FK list (minimal)
    filtered_fk_list AS (
        SELECT
            c.oid,
            c.conname,
            c.conrelid,
            c.confrelid,
            c.conkey,
            c.confkey
        FROM pg_catalog.pg_constraint AS c
        WHERE
            c.contype IN ('f')
            AND c.conrelid IN (SELECT oid FROM filtered_class_list WHERE relkind IN ('r', 'm', 'p'))
            AND c.confrelid IN (SELECT oid FROM filtered_class_list WHERE relkind IN ('r', 'm', 'p'))
    ),
    -- filtered FK list with attribute
    filtered_fk_list_attribute AS (
        SELECT
            cfk.oid,
            cfk.conname,
            cfk.conrelid,
            cfk.confrelid,
            cfk_conkey.conkey_order AS att_order,
            cfk_conkey.conkey_number,
            cfk_confkey.confkey_number,
            rel_att.attname AS rel_att_name,
            rel_att.atttypid AS rel_att_type_id,
            rel_att.atttypmod AS rel_att_type_mod,
            rel_att.attnotnull AS rel_att_notnull,
            frel_att.attname AS frel_att_name,
            frel_att.atttypid AS frel_att_type_id,
            frel_att.atttypmod AS frel_att_type_mod,
            frel_att.attnotnull AS frel_att_notnull
        FROM filtered_fk_list AS cfk
            CROSS JOIN LATERAL UNNEST(cfk.conkey) WITH ORDINALITY AS cfk_conkey(conkey_number, conkey_order)
            LEFT JOIN LATERAL UNNEST(cfk.confkey) WITH ORDINALITY AS cfk_confkey(confkey_number, confkey_order)
                ON cfk_conkey.conkey_order = cfk_confkey.confkey_order
            LEFT JOIN pg_catalog.pg_attribute AS rel_att
                ON rel_att.attrelid = cfk.conrelid AND rel_att.attnum = cfk_conkey.conkey_number
            LEFT JOIN pg_catalog.pg_attribute AS frel_att
                ON frel_att.attrelid = cfk.confrelid AND frel_att.attnum = cfk_confkey.confkey_number
    ),
    -- fk1001 - fk uses mismatched types
    check_fk1001 AS (
        SELECT
            c.oid AS object_id,
            c.conname AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', c.oid,
                'object_name', c.conname,
                'object_type', ch.object_type,
                'relation_name', t.class_name,
                'relation_att_names', c.rel_att_names,
                'foreign_relation_name', tf.class_name,
                'foreign_relation_att_names', c.frel_att_names,
                'check', ch.*
            ) AS check_result_json
        FROM (
            SELECT
                oid,
                conname,
                conrelid,
                confrelid,
                array_agg (rel_att_name order by att_order ) as rel_att_names,
                array_agg (frel_att_name order by att_order ) as frel_att_names
            FROM filtered_fk_list_attribute
            WHERE
                ((rel_att_type_id <> frel_att_type_id) OR (rel_att_type_mod <> frel_att_type_mod))
            GROUP BY 1, 2, 3, 4
        ) AS c
            INNER JOIN filtered_class_list AS t
                ON t.oid = c.conrelid
            INNER JOIN filtered_class_list AS tf
                ON tf.oid = c.confrelid
            LEFT JOIN check_list ch ON ch.check_code = 'fk1001'
        WHERE
            (SELECT enable_check_fk1001 FROM conf)
    ),
    -- fk1002 - fk uses nullable columns
    check_fk1002 AS (
        SELECT
            c.oid AS object_id,
            c.conname AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', c.oid,
                'object_name', c.conname,
                'object_type', ch.object_type,
                'relation_name', t.class_name,
                'relation_att_names', c.rel_att_names,
                'check', ch.*
            ) AS check_result_json
        FROM (
            SELECT
                oid,
                conname,
                conrelid,
                confrelid,
                array_agg (rel_att_name order by att_order ) as rel_att_names
            FROM filtered_fk_list_attribute
            WHERE
                (NOT rel_att_notnull)
            GROUP BY 1, 2, 3, 4
        ) AS c
            INNER JOIN filtered_class_list AS t
                ON t.oid = c.conrelid
            INNER JOIN filtered_class_list AS tf
                ON tf.oid = c.confrelid
            LEFT JOIN check_list ch ON ch.check_code = 'fk1002'
        WHERE
            (SELECT enable_check_fk1002 FROM conf)
    ),
    -- fk1007 - not involved in foreign keys
    check_fk1007 AS (
        SELECT
            t.oid AS object_id,
            t.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', t.oid,
                'object_name', t.class_name,
                'object_type', ch.object_type,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_class_list AS t
            LEFT JOIN check_list ch ON ch.check_code = 'fk1007'
        WHERE
            (SELECT enable_check_fk1007 FROM conf)
            AND relkind IN ('r', 'p')
            AND t.oid NOT IN (SELECT conrelid FROM filtered_fk_list)
            AND t.oid NOT IN (SELECT confrelid FROM filtered_fk_list)
    ),
    -- filtered constraint list (minimal)
    filtered_c_list AS (
        SELECT
            c.oid,
            c.contype,
            c.conname,
            c.conrelid,
            c.confrelid,
            c.conkey,
            c.confkey,
            c.convalidated
        FROM pg_catalog.pg_constraint AS c
        WHERE
            c.conrelid IN (SELECT oid FROM filtered_class_list WHERE relkind IN ('r', 'm', 'p'))
    ),
    -- c1001 - constraint not validated
    check_c1001 AS (
        SELECT
            c.oid AS object_id,
            c.conname AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', c.oid,
                'object_name', c.conname,
                'object_type', ch.object_type,
                'relation_name', t.class_name,
                'constraint_type', c.contype,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_c_list AS c
            INNER JOIN filtered_class_list AS t
                ON t.oid = c.conrelid AND c.contype IN ('c', 'f') AND (NOT c.convalidated)
            LEFT JOIN check_list ch ON ch.check_code = 'c1001'
        WHERE
            (SELECT enable_check_c1001 FROM conf)
    ),
    -- filtered and extended index list
    filtered_index_list AS (
        SELECT
            ic.oid,
            ic.class_name,
            ic.relam,
            ic.relnatts,
            i.*,
            pg_get_indexdef(ic.oid) AS object_definition,
            -- simplification of definition
            regexp_replace( -- ' DESC,'
            regexp_replace( -- ' DESC\)'
            regexp_replace( -- ' NULLS LAST,'
            regexp_replace( -- ' NULLS LAST\)'
            regexp_replace( -- ' NULLS FIRST,'
            regexp_replace( -- ' NULLS FIRST\)'
            regexp_replace( -- ' INDEX .* ON '
            		pg_get_indexdef(ic.oid), ' INDEX .* ON ', ' INDEX ON '),
            		' NULLS FIRST\)', ')'),
            		' NULLS FIRST,', ','),
            		' NULLS LAST\)', ')'),
            		' NULLS LAST,', ','),
            		' DESC\)', ')'),
            		' DESC,', ',')
            	 AS simplified_object_definition,
            (SELECT array_agg(c.conname) FROM pg_catalog.pg_constraint AS c WHERE c.conindid = ic.oid)
                AS used_in_constraint
        FROM pg_catalog.pg_index AS i
            INNER JOIN filtered_class_list ic ON i.indexrelid = ic.oid
    ),
    -- i1001 - similar indexes
    check_i1001 AS (
        SELECT
            i.oid AS object_id,
            i.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', i.oid,
                'object_name', i.class_name,
                'object_type', ch.object_type,
                'relation_name', t.class_name,
                'similar_index_name', si.class_name,
                'object_definition', i.object_definition,
                'simplified_object_definition', i.simplified_object_definition,
                'similar_index_definition', si.object_definition,
                'index_used_in_constraint', i.used_in_constraint,
                'similar_index_used_in_constraint', si.used_in_constraint,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_index_list AS i
            INNER JOIN filtered_class_list AS t ON i.indrelid = t.oid
            INNER JOIN filtered_index_list AS si ON i.oid < si.oid AND i.indrelid = si.indrelid AND i.relam = si.relam
                AND i.relnatts = si.relnatts AND i.indnkeyatts = si.indnkeyatts
                AND i.simplified_object_definition = si.simplified_object_definition
            LEFT JOIN check_list ch ON ch.check_code = 'i1001'
        WHERE
            (SELECT enable_check_i1001 FROM conf)
    ),
    --
    index_bad_signs AS (
        SELECT oid, array_agg(value) AS bad_signs FROM (
            SELECT oid, 'not valid' AS value FROM filtered_index_list WHERE indisvalid IS NOT TRUE
            UNION ALL
            SELECT oid, 'not ready' AS value FROM filtered_index_list WHERE indisready IS NOT TRUE
        ) AS t
        GROUP BY oid
    ),
    -- i1002 - index has bad signs
    check_i1002 AS (
        SELECT
            i.oid AS object_id,
            i.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', i.oid,
                'object_name', i.class_name,
                'object_type', ch.object_type,
                'relation_name', t.class_name,
                'bad_signs', ibs.bad_signs,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_index_list AS i
            INNER JOIN filtered_class_list AS t ON i.indrelid = t.oid
            INNER JOIN index_bad_signs AS ibs ON i.oid = ibs.oid
            LEFT JOIN check_list ch ON ch.check_code = 'i1002'
        WHERE
            (SELECT enable_check_i1002 FROM conf)
    ),
    -- i1003 - similar indexes unique and not unique
    check_i1003 AS (
        SELECT
            ui.oid AS object_id,
            ui.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', ui.oid,
                'object_name', ui.class_name,
                'object_type', ch.object_type,
                'relation_name', t.class_name,
                'similar_index_name', nui.class_name,
                'object_definition', ui.object_definition,
                'simplified_object_definition', ui.simplified_object_definition,
                'similar_index_definition', nui.object_definition,
                'index_used_in_constraint', ui.used_in_constraint,
                'similar_index_used_in_constraint', nui.used_in_constraint,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_index_list AS ui
            INNER JOIN filtered_class_list AS t ON ui.indrelid = t.oid
            INNER JOIN filtered_index_list AS nui ON ui.indrelid = nui.indrelid AND ui.relam = nui.relam
                AND ui.indisunique AND NOT nui.indisunique
                AND ui.relnatts = nui.relnatts AND ui.indnkeyatts = nui.indnkeyatts
                AND replace(ui.simplified_object_definition, ' UNIQUE ', ' ') = nui.simplified_object_definition
            LEFT JOIN check_list ch ON ch.check_code = 'i1003'
        WHERE
            (SELECT enable_check_i1003 FROM conf)
    ),
    -- filtered and extended index list - roughly
    index_definition_roughly_list AS (
        SELECT
            filtered_index_list.*,
            -- simplification of definition
            replace(        -- ' UNIQUE '
            regexp_replace( -- ' INCLUDE'
            regexp_replace( -- ' WHERE'
            		simplified_object_definition, ' WHERE .*', ''),
            		' INCLUDE .*', ''),
                    ' UNIQUE ', ' ')
            	 AS simplified_object_definition_roughly
        FROM filtered_index_list
    ),
    -- i1005 - similar indexes (roughly)
    check_i1005 AS (
        SELECT
            i.oid AS object_id,
            i.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', i.oid,
                'object_name', i.class_name,
                'object_type', ch.object_type,
                'relation_name', t.class_name,
                'similar_index_name', si.class_name,
                'object_definition', i.object_definition,
                'simplified_object_definition_roughly', i.simplified_object_definition_roughly,
                'similar_index_definition', si.object_definition,
                'index_used_in_constraint', i.used_in_constraint,
                'similar_index_used_in_constraint', si.used_in_constraint,
                'check', ch.*
            ) AS check_result_json
        FROM index_definition_roughly_list AS i
            INNER JOIN filtered_class_list AS t ON i.indrelid = t.oid
            INNER JOIN index_definition_roughly_list AS si ON i.oid < si.oid AND i.indrelid = si.indrelid
                AND i.relam = si.relam
                AND i.simplified_object_definition_roughly = si.simplified_object_definition_roughly
            LEFT JOIN check_list ch ON ch.check_code = 'i1005'
        WHERE
            (SELECT enable_check_i1005 FROM conf)
    ),
    -- i1010 - b-tree index for array column
    check_i1010 AS (
        SELECT
            i.oid AS object_id,
            i.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', i.oid,
                'object_name', i.class_name,
                'object_type', ch.object_type,
                'relation_name', t.class_name,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_index_list AS i
            INNER JOIN filtered_class_list AS t ON i.indrelid = t.oid
            INNER JOIN pg_catalog.pg_am AS a ON i.relam = a.oid AND a.amname = 'btree'
            LEFT JOIN check_list ch ON ch.check_code = 'i1010'
        WHERE
            (SELECT enable_check_i1010 FROM conf)
            AND EXISTS (SELECT * FROM pg_catalog.pg_attribute AS att
                        INNER JOIN pg_catalog.pg_type AS typ ON typ.oid = att.atttypid
                        WHERE att.attrelid = i.indrelid
                            AND att.attnum = ANY ((string_to_array(indkey::text, ' ')::int2[])[1:indnkeyatts])
                            AND typ.typcategory = 'A')
    ),
    --
    filtered_sequence_list AS (
        SELECT
            sc.*,
            s.*,
            COALESCE(sv.last_value, s.seqstart) AS last_value,
            CASE
                WHEN s.seqincrement > 0 THEN 100.0*(s.seqmax - COALESCE(sv.last_value, s.seqstart))/(s.seqmax - s.seqmin)
                ELSE 100.0*(COALESCE(sv.last_value, s.seqstart) - s.seqmin)/(s.seqmax - s.seqmin)
            END::numeric(5, 2) AS unused_values_percent
        FROM pg_catalog.pg_sequence AS s
            INNER JOIN filtered_class_list sc ON s.seqrelid = sc.oid
            LEFT JOIN pg_catalog.pg_sequences sv ON concat(sv.schemaname, '.',  sv.sequencename) = sc.class_name
    ),
    -- s1010 less 5% unused sequence values
    check_s1010 AS (
        SELECT
            s.oid AS object_id,
            s.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', s.oid,
                'object_name', s.class_name,
                'object_type', ch.object_type,
                'unused_values_percent', s.unused_values_percent,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_sequence_list AS s
            LEFT JOIN check_list ch ON ch.check_code = 's1010'
        WHERE
            (SELECT enable_check_s1010 FROM conf)
            AND NOT s.seqcycle
            AND 5.0 >= s.unused_values_percent
    ),
    -- s1011 less 10% unused sequence values
    check_s1011 AS (
        SELECT
            s.oid AS object_id,
            s.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', s.oid,
                'object_name', s.class_name,
                'object_type', ch.object_type,
                'unused_values_percent', s.unused_values_percent,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_sequence_list AS s
            LEFT JOIN check_list ch ON ch.check_code = 's1011'
        WHERE
            (SELECT enable_check_s1011 FROM conf)
            AND NOT s.seqcycle
            AND 10.0 >= s.unused_values_percent
            -- not in parent check
            AND NOT ((SELECT enable_check_s1010 FROM conf) AND (s.oid IN (SELECT object_id FROM check_s1010)))
    ),
    -- s1012 less 20% unused sequence values
    check_s1012 AS (
        SELECT
            s.oid AS object_id,
            s.class_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', s.oid,
                'object_name', s.class_name,
                'object_type', ch.object_type,
                'unused_values_percent', s.unused_values_percent,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_sequence_list AS s
            LEFT JOIN check_list ch ON ch.check_code = 's1012'
        WHERE
            (SELECT enable_check_s1012 FROM conf)
            AND NOT s.seqcycle
            AND 20.0 >= s.unused_values_percent
            -- not in parent check
            AND NOT ((SELECT enable_check_s1010 FROM conf) AND (s.oid IN (SELECT object_id FROM check_s1010)))
            AND NOT ((SELECT enable_check_s1011 FROM conf) AND (s.oid IN (SELECT object_id FROM check_s1011)))
    ),
    -- filtered schema list with simplified name
    filtered_schema_list_simplified_name AS (
        SELECT
            fsl.*,
            lower(regexp_replace(fsl.nspname, '\s+', '', 'g')) AS simplified_schema_name
        FROM filtered_schema_list AS fsl
    ),
    -- n1001 confusion in name of schemas
    check_n1001 AS (
        SELECT
            s1.oid AS object_id,
            s1.formatted_schema_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', s1.oid,
                'object_name', s1.formatted_schema_name,
                'object_type', ch.object_type,
                'simplified_object_name', s1.simplified_schema_name,
                'similar_object_name', s2.formatted_schema_name,
                'similar_object_id', s2.oid,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_schema_list_simplified_name AS s1
            INNER JOIN filtered_schema_list_simplified_name AS s2
                ON s1.simplified_schema_name = s2.simplified_schema_name AND s1.oid < s2.oid
            LEFT JOIN check_list ch ON ch.check_code = 'n1001'
        WHERE
            (SELECT enable_check_n1001 FROM conf)
    ),
    filtered_attribute_list_simplified_name AS (
        SELECT
            a.*,
            fcl.formatted_class_name,
            concat(fcl.formatted_class_name, '.',  format('%I', a.attname)) AS formatted_attribute_name,
            lower(regexp_replace(a.attname, '\s+', '', 'g')) AS simplified_attribute_name
        FROM pg_catalog.pg_attribute AS a
            INNER JOIN filtered_class_list AS fcl ON a.attrelid = fcl.oid
        WHERE
            a.attnum >= 1 AND fcl.relkind IN ('r', 'v', 'm', 'p')
    ),
    -- n1005 confusion in name of relation attributes
    check_n1005 AS (
        SELECT
            a1.attnum AS object_id,
            a1.formatted_attribute_name AS object_name,
            ch.object_type AS object_type,
            ch.check_code,
            ch.check_level,
            ch.check_name,
            json_build_object(
                'object_id', a1.attnum,
                'object_name', a1.formatted_attribute_name,
                'object_type', ch.object_type,
                'simplified_object_name', a1.simplified_attribute_name,
                'similar_object_name', a2.formatted_attribute_name,
                'similar_object_id', a2.attnum,
                'relation_name', a1.formatted_class_name,
                'relation_id', a1.attrelid,
                'check', ch.*
            ) AS check_result_json
        FROM filtered_attribute_list_simplified_name AS a1
            INNER JOIN filtered_attribute_list_simplified_name AS a2
                ON a1.simplified_attribute_name = a2.simplified_attribute_name AND a1.attrelid = a2.attrelid
                    AND a1.attnum < a2.attnum
            LEFT JOIN check_list ch ON ch.check_code = 'n1005'
        WHERE
            (SELECT enable_check_n1005 FROM conf)
    )
-- result
SELECT object_id, object_name, object_type, check_code, check_level, check_name, check_result_json FROM (
    SELECT * FROM check_no1001 -- no1001 - no unique key
    UNION ALL
    SELECT * FROM check_no1002 -- no1002 - no primary key constraint
    UNION ALL
    SELECT * FROM check_fk1001 -- fk1001 - fk uses mismatched types
    UNION ALL
    SELECT * FROM check_fk1002 -- fk1002 - fk uses nullable columns
    UNION ALL
    SELECT * FROM check_fk1007 -- fk1007 - not involved in foreign keys
    UNION ALL
    SELECT * FROM check_c1001  -- c1001 - constraint not validated
    UNION ALL
    SELECT * FROM check_i1001  -- i1001 - similar indexes
    UNION ALL
    SELECT * FROM check_i1002  -- i1002 - index has bad signs
    UNION ALL
    SELECT * FROM check_i1003  -- i1003 - similar indexes unique and not unique
    UNION ALL
    SELECT * FROM check_i1005  -- i1005 - similar indexes (roughly)
    UNION ALL
    SELECT * FROM check_i1010  -- i1010 - b-tree index for array column
    UNION ALL
    SELECT * FROM check_s1010  -- s1010 less 5% unused sequence values
    UNION ALL
    SELECT * FROM check_s1011  -- s1011 less 10% unused sequence values
    UNION ALL
    SELECT * FROM check_s1012  -- s1012 less 20% unused sequence values
    UNION ALL
    SELECT * FROM check_n1001  -- n1001 confusion in name of schemas
    UNION ALL
    SELECT * FROM check_n1005  -- n1001 confusion in name of relation attributes
) AS t
-- result filter (for error suppression)
-- >>> WHERE
ORDER BY check_level, check_code, object_name
;
