 
CREATE PROC dbo.GenerateModelWithTable(
	@TableName nvarchar(200)
)AS
BEGIN

DECLARE @props NVARCHAR(MAX) =
        (
            SELECT 'public ' + dbo.fn_getCSharpDataType(DATA_TYPE) + ' ' + COLUMN_NAME + ' { get; set; } '
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = 'product'
            FOR XML PATH('')
        );
DECLARE @Collection NVARCHAR(MAX) =
        (
            SELECT ' public virtual ICollection<' + MTO.TABLE_NAME + '> ' + MTO.TABLE_NAME + 'List  { get; set; }'
            FROM
            (
                SELECT tab.name tblName,
                       fk.name,
                       kCU.TABLE_SCHEMA,
                       kCU.TABLE_NAME,
                       kCU.COLUMN_NAME,
                       RC.MATCH_OPTION,
                       RC.UPDATE_RULE,
                       RC.DELETE_RULE
                FROM sys.tables AS tab
                    LEFT JOIN sys.foreign_keys AS fk
                        ON fk.referenced_object_id = tab.object_id
                    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kCU
                        ON kCU.CONSTRAINT_NAME = fk.name
                    INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
                        ON RC.CONSTRAINT_NAME = fk.name
                WHERE tab.name = 'Product'
            ) MTO
            FOR XML PATH('')
        );
 DECLARE @Rells NVARCHAR(MAX) =
        (
            SELECT 'public virtual ' + OTM.tableRellName + ' ' + OTM.COLUMN_NAME + ' { get; set; }'
            FROM
            (
                SELECT fk.name,
                       kCU.TABLE_SCHEMA,
                       kCU.TABLE_NAME,
                       kCU.COLUMN_NAME,
                       RC.MATCH_OPTION,
                       RC.UPDATE_RULE,
                       RC.DELETE_RULE,
                       o.name tableRellName
                FROM sys.tables AS tab
                    LEFT JOIN sys.foreign_keys AS fk
                        ON fk.parent_object_id = tab.object_id
                    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kCU
                        ON kCU.CONSTRAINT_NAME = fk.name
                    INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
                        ON RC.CONSTRAINT_NAME = fk.name
                    INNER JOIN sys.objects o
                        ON fk.referenced_object_id = o.object_id
                WHERE tab.name = 'Product'
            ) OTM
            FOR XML PATH('')
        );
DECLARE @ConstructorHashSet NVARCHAR(MAX) =
        ( SELECT  MTO.TABLE_NAME + 'List = new HashSet'+'<'+ MTO.TABLE_NAME+'>'+'();'
            FROM
            (
                SELECT tab.name tblName,
                       fk.name,
                       kCU.TABLE_SCHEMA,
                       kCU.TABLE_NAME,
                       kCU.COLUMN_NAME,
                       RC.MATCH_OPTION,
                       RC.UPDATE_RULE,
                       RC.DELETE_RULE
                FROM sys.tables AS tab
                    LEFT JOIN sys.foreign_keys AS fk
                        ON fk.referenced_object_id = tab.object_id
                    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kCU
                        ON kCU.CONSTRAINT_NAME = fk.name
                    INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
                        ON RC.CONSTRAINT_NAME = fk.name
                WHERE tab.name = 'Product'
            ) MTO
            FOR XML PATH('')
        );
DECLARE @Constructor NVARCHAR(MAX) =
        (
            SELECT 'public ' + name + '() {'+@ConstructorHashSet+ ' }'
            FROM sys.tables
            WHERE name = 'product'
        );
DECLARE @ClassModelstructure NVARCHAR(MAX) =
        (
            SELECT 'public partial class ' + name + ' {'+@Constructor+' ' + @props + ' ' + @Rells + ' ' + @Collection + ' }'
            FROM sys.tables
            WHERE name = 'product'
        );
SET @ClassModelstructure = REPLACE(@ClassModelstructure,'&lt;',CHAR('60'))
SET @ClassModelstructure = REPLACE(@ClassModelstructure,'&gt;',CHAR('62'))
SELECT @ClassModelstructure  ClassModelstructure


DECLARE @Default_constraints NVARCHAR(MAX) =
        (
SELECT 'entity.Property(e => e.'+col.name+').HasColumnName("'+col.name+'").HasDefaultValueSql("'+con.definition+'");',*
FROM sys.default_constraints con
    JOIN sys.objects o
        ON o.object_id = con.parent_object_id
				INNER JOIN sys.columns col on col.object_id = o.object_id AND column_id = con.parent_column_id
WHERE o.name = 'product'
            FOR XML PATH('')
        );
DECLARE @propsDataTypeConfig NVARCHAR(MAX) =
        (
            SELECT 'entity.Property(e => e.'+COLUMN_NAME+').HasColumnType("'+DATA_TYPE
						+
						CASE 
						WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL AND CHARACTER_MAXIMUM_LENGTH<> -1  THEN '('+CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(MAX))+')'
						WHEN  CHARACTER_MAXIMUM_LENGTH= -1 THEN '(MAX)'
						 WHEN  CHARACTER_MAXIMUM_LENGTH IS NULL AND DATA_TYPE= 'decimal' AND  NUMERIC_PRECISION IS NOT NULL THEN '('+CAST(NUMERIC_PRECISION AS NVARCHAR(MAX))+','+CAST(NUMERIC_SCALE AS NVARCHAR(MAX))+')'
						ELSE ''END 
						+'");',*
             FROM  INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = 'product'
            FOR XML PATH('')
        );
DECLARE @RellsConfig NVARCHAR(MAX) =
        (
            SELECT 'entity.HasOne(d => d.'+OTM.COLUMN_NAME+').WithMany(p => p.'+OTM.COLUMN_NAME+').HasForeignKey(d => d.'+OTM.COLUMN_NAME+').HasConstraintName("'+OTM.name+'");'
            ,*FROM
            (
                SELECT fk.name,
                       kCU.TABLE_SCHEMA,
                       kCU.TABLE_NAME,
                       kCU.COLUMN_NAME,
                       RC.MATCH_OPTION,
                       RC.UPDATE_RULE,
                       RC.DELETE_RULE,
                       o.name tableRellName
                FROM sys.tables AS tab
                    LEFT JOIN sys.foreign_keys AS fk
                        ON fk.parent_object_id = tab.object_id
                    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kCU
                        ON kCU.CONSTRAINT_NAME = fk.name
                    INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
                        ON RC.CONSTRAINT_NAME = fk.name
                    INNER JOIN sys.objects o
                        ON fk.referenced_object_id = o.object_id
                WHERE tab.name = 'Product'
            ) OTM
            FOR XML PATH('')
        );
DECLARE @Configstructure NVARCHAR(MAX) =
        (
            SELECT 'modelBuilder.Entity<'+tables.name+'>(entity =>{ entity.ToTable("'+tables.name+'", "'+schemas.name+'"); '+ @Default_constraints + ' '+@propsDataTypeConfig + '  ' +@RellsConfig +' });'
            FROM sys.tables
						INNER JOIN sys.schemas ON schemas.schema_id = tables.schema_id
            WHERE tables.name = 'product'
        );
SET @Configstructure = REPLACE(@Configstructure,'&lt;',CHAR('60'))
SET @Configstructure = REPLACE(@Configstructure,'&gt;',CHAR('62'))
SELECT @Configstructure ClassModelstructure
 

 END
 
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

	CREATE FUNCTION dbo.fn_getCSharpDataType(@SqlDataType NVARCHAR(max)) 
	RETURNS  NVARCHAR(max)
 	AS
	BEGIN
	DECLARE  @result NVARCHAR(max) =(
	SELECT CASE @SqlDataType
    WHEN 'bigint' THEN 'Int64'
    WHEN 'binary' THEN 'binary'
    WHEN 'bit' THEN 'Boolean'
    WHEN 'char' THEN 'string'
    WHEN 'date ' THEN 'DateTime'
    WHEN 'datetime' THEN 'DateTime'
    WHEN 'datetime2' THEN 'DateTime'
    WHEN 'datetimeoffset' THEN 'DateTimeOffset'
    WHEN 'decimal' THEN 'Decimal'
    WHEN 'FILESTREAM' THEN 'Byte[]'
    WHEN 'float' THEN 'Double'
    WHEN 'image' THEN 'Byte[]'
    WHEN 'int' THEN 'Int32'
    WHEN 'money' THEN 'Decimal'
    WHEN 'nchar' THEN 'string'
    WHEN 'ntext' THEN 'string'
    WHEN 'numeric' THEN 'Decimal'
    WHEN 'nvarchar' THEN 'string'
    WHEN 'real' THEN 'Single'
    WHEN 'rowversion' THEN 'Byte[]'
    WHEN 'smalldatetime' THEN 'DateTime'
    WHEN 'smallint' THEN 'Int16'
    WHEN 'smallmoney' THEN 'Decimal'
    WHEN 'sql_variant' THEN 'Object'
    WHEN 'text' THEN 'string'
    WHEN 'time' THEN 'TimeSpan'
    WHEN 'timestamp' THEN 'Byte[]'
    WHEN 'tinyint' THEN 'Byte'
    WHEN 'uniqueidentifier' THEN 'Guid'
    WHEN 'varbinary' THEN 'Byte[]'
    WHEN 'varchar' THEN 'String'
    WHEN 'xml' THEN 'Xml'
     ELSE 'string' END)
  		RETURN @result 
	END
	
GO

 
