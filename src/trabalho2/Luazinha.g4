grammar Luazinha;


@members{
static String grupo = "<Coloque os RAs do seu grupo aqui>";
PilhaDeTabelas pilhaDeTabelas = new PilhaDeTabelas();
}


programa : { pilhaDeTabelas.empilhar(new TabelaDeSimbolos("global")); }
           trecho
           { pilhaDeTabelas.desempilhar(); }
         ;

trecho : (comando ';'?)* (ultimocomando ';'?)?
       ;

bloco : trecho
      ;

comando :  listavar '=' listaexp {
                                             TabelaDeSimbolos tabelasimb = pilhaDeTabelas.topo(); //Tabela de simbolos do escopo atual
                                             for(String nome : $listavar.nomes){          // Para todos os nomes de variáveis presente na lista de variáveis, adiciona eles
                                               if (pilhaDeTabelas.existeSimbolo(nome) == false)  //Caso não exista o símbolo no escopo atual ou acima.
                                                  tabelasimb.adicionarSimbolo(nome, "variavel"); //Adiciona um único símbolo de um tipo na Tabela de Simbolos
                                                 //a função adicionarSimbolo está definido em TabelaDeSimbolos.java e tem como parâmetros uma String nome e uma String tipo
                                             }
                                           }
        |  chamadadefuncao
        |  'do' bloco 'end'
        |  'while' exp 'do' bloco 'end'
        |  'repeat' bloco 'until' exp
        |  'if' exp 'then' bloco ('elseif' exp 'then' bloco)* ('else' bloco)? 'end'
        |  'for' NOME '=' exp ',' exp (',' exp)? 'do'
           {pilhaDeTabelas.empilhar(new TabelaDeSimbolos("for")); } //Cria e empilha tabela de simbolos de escopo "for"
           bloco
           {TabelaDeSimbolos tabFor = pilhaDeTabelas.topo(); //Tabela de simbolos do escopo atual
            if (pilhaDeTabelas.existeSimbolo($NOME.getText()) == false) //Caso não exista no escopo atual ou acima
                tabFor.adicionarSimbolo($NOME.getText(), "variavel"); //Adiciona o símbolo na tabela de simbolos
            pilhaDeTabelas.desempilhar(); } //Desempilha a tabela de simbolos do escoro "for"
         'end'
        |  'for' listadenomes 'in' listaexp 'do' { pilhaDeTabelas.empilhar(new TabelaDeSimbolos("for")); } bloco
        {
            TabelaDeSimbolos tabFor = pilhaDeTabelas.topo(); //Tabela de simbolos do escopo atual
            for(String nome : $listadenomes.nomes){       // Para todos os nomes de símbolos presente na lista de símbolos, adiciona eles ao escopo "for"
                if (pilhaDeTabelas.topo().existeSimbolo(nome) == false) //Caso não exista o símbolo no escopo atual
                   tabFor.adicionarSimbolo(nome, "variavel"); //Adiciona o símbolo na tabela de simbolos
            }
            pilhaDeTabelas.desempilhar(); }'end' //Adicao da tabela de simbolos for
        |  'function' nomedafuncao { pilhaDeTabelas.empilhar(new TabelaDeSimbolos($nomedafuncao.text)); } corpodafuncao { pilhaDeTabelas.desempilhar(); } //Adicao da tabela de simbolos para funcao
        |  'local' 'function' NOME { pilhaDeTabelas.empilhar(new TabelaDeSimbolos($NOME.text)); } corpodafuncao { pilhaDeTabelas.desempilhar(); }
        |  'local' listadenomes ('=' listaexp)?
            {
                     TabelaDeSimbolos tsLocal = pilhaDeTabelas.topo(); //Pega a tabela de simbolos do escopo atual
                     for(String nome : $listadenomes.nomes){ //Adiciona todos as variaveis do bloco local
                           tsLocal.adicionarSimbolo(nome, "variavel");
                     }
                    }
        ;

ultimocomando : 'return' (listaexp)? | 'break'
              ;

nomedafuncao returns [ String nome, boolean metodo ]
@init { $metodo = false; }
    : n1=NOME { $nome = $n1.getText(); }
      ('.' n2=NOME { $nome += "." + $n2.getText(); })*
      (':' n3=NOME { $metodo = true; $nome += "." + $n3.getText(); })?
    ;

listavar returns [ List<String> nomes ]
@init { $nomes = new ArrayList<String>(); }
    : v1=var { $nomes.add($v1.nome); }
      (',' v2=var { $nomes.add($v2.nome); }
      )*
    ;

var returns [ String nome, int linha, int coluna ]
    :  NOME { $nome = $NOME.getText(); $linha = $NOME.line; $coluna = $NOME.pos; }
    |  expprefixo '[' exp ']'
    |  expprefixo '.' NOME
    ;

listadenomes returns [ List<String> nomes ]
@init{ $nomes = new ArrayList<String>(); }
    : n1=NOME { $nomes.add($n1.getText()); }
      (',' n2=NOME { $nomes.add($n2.getText()); } )*
    ;

listaexp : (exp ',')* exp
         ;

exp :  'nil' | 'false' | 'true' | NUMERO | CADEIA | '...' | funcao |
       expprefixo2 | construtortabela | exp opbin exp | opunaria exp
    ;


expprefixo : NOME ( '[' exp ']' | '.' NOME )*
           ;

expprefixo2 : var | chamadadefuncao | '(' exp ')'
           ;

chamadadefuncao :  expprefixo args |
                   expprefixo ':' NOME args
                ;

args :  '(' (listaexp)? ')' | construtortabela | CADEIA
     ;

funcao : 'function' corpodafuncao
       ;

corpodafuncao : '(' (listapar)? ')' bloco 'end'
              ;

listapar : listadenomes
            {TabelaDeSimbolos tabParam = pilhaDeTabelas.topo(); //Tabela de simbolos do escopo atual
               for(String nome : $listadenomes.nomes){ // Para todos os nomes presente na lista de parâmetros, adiciona eles
                  if (pilhaDeTabelas.topo().existeSimbolo(nome)==false) //Caso não tenha sido declarado
                      tabParam.adicionarSimbolo(nome, "parametro"); //Adiciona o parametro
               }
            }
         (',' '...')?
         | '...'
         ;

construtortabela : '{' (listadecampos)? '}'
                 ;

listadecampos : campo (separadordecampos campo)* (separadordecampos)?
              ;

campo : '[' exp ']' '=' exp | NOME '=' exp | exp
      ;

separadordecampos : ',' | ';'
                  ;

opbin : '+' | '-' | '*' | '/' | '^' | '%' | '..' | '<' |
        '<=' | '>' | '>=' | '==' | '~=' | 'and' | 'or'
      ;

opunaria : '-' | 'not' | '#'
         ;


NOME	:	('a'..'z' | 'A'..'Z' | '_') ('a'..'z' | 'A'..'Z' | '0'..'9' | '_')*;
CADEIA	:	'\'' ~('\n' | '\r' | '\'')* '\'' | '"' ~('\n' | '\r' | '"')* '"';
NUMERO	:	('0'..'9')+ EXPOENTE? | ('0'..'9')+ '.' ('0'..'9')* EXPOENTE?
		| '.' ('0'..'9')+ EXPOENTE?;
fragment
EXPOENTE	:	('e' | 'E') ( '+' | '-')? ('0'..'9')+;
COMENTARIO
	:	'--' ~('\n' | '\r')* '\r'? '\n' {skip();};
WS	:	(' ' | '\t' | '\r' | '\n') {skip();};
