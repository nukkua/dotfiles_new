local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("php", {
	s("html", {
		t({ "<!DOCTYPE html>", "<html lang=\"en\">", "<head>", "    <meta charset=\"UTF-8\">",
			"    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">", "    <title>" }),
		i(1, "Document"),
		t({ "</title>", "</head>", "<body>", "" }),
		i(2),
		t({ "", "</body>", "</html>" }),
	}),
})

ls.add_snippets("php", {
	s("hasMany", {
		t({ "public function " }), i(1, "related"), t({ "() {", "\treturn $this->hasMany(" }),
		i(2, "RelatedModel"), t({ "::class);", "}", "" }),
	}),
})

ls.add_snippets("php", {
	s("model", {
		t({ "<?php", "", "namespace App\\Models;", "",
			"use Illuminate\\Database\\Eloquent\\Factories\\HasFactory;",
			"use Illuminate\\Database\\Eloquent\\Model;", "", "class " }), i(1, "ModelName"), t({
		" extends Model", "{", "\tuse HasFactory;", "", "\tprotected $fillable = [", "\t\t" }), i(2,
		"'field1', 'field2'"), t({ "", "\t];", "", "}" })
	}),
})

ls.add_snippets("php", {
	s("controller", {
		t({ "<?php", "", "namespace App\\Http\\Controllers;", "", "use Illuminate\\Http\\Request;",
			"use App\\Http\\Controllers\\Controller;", "", "class " }), i(1, "ControllerName"), t({
		" extends Controller", "{", "\tpublic function " }), i(2, "methodName"), t({ "(Request $request)", "\t{",
		"\t\t" }), i(0), t({ "", "\t}", "}" })
	}),
})

ls.add_snippets("php", {
	s("belongsTo", {
		t({ "public function " }), i(1, "related"), t({ "() {", "\treturn $this->belongsTo(" }),
		i(2, "RelatedModel"), t({ "::class);", "}", "" }),
	}),
})

ls.add_snippets("php", {
	s("hasOne", {
		t({ "public function " }), i(1, "related"), t({ "() {", "\treturn $this->hasOne(" }),
		i(2, "RelatedModel"), t({ "::class);", "}", "" }),
	}),
})


ls.add_snippets("php", {
	s("migration", {
		t({ "<?php", "", "use Illuminate\\Database\\Migrations\\Migration;",
			"use Illuminate\\Database\\Schema\\Blueprint;", "use Illuminate\\Support\\Facades\\Schema;", "",
			"class " }), i(1, "MigrationName"), t({ " extends Migration", "{", "\tpublic function up()",
		"\t{", "\t\tSchema::create('" }), i(2, "table_name"), t({ "', function (Blueprint $table) {",
		"\t\t\t$table->id();", "\t\t\t" }), i(0), t({ "", "\t\t\t$table->timestamps();", "\t\t});", "\t}", "",
		"\tpublic function down()", "\t{", "\t\tSchema::dropIfExists('" }), i(2, "table_name"), t({ "');", "\t}",
		"}" })
	}),
})
