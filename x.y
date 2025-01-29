%{

    #include "stdio.h"
    #include "string.h"
    #include "defs.h"
    #include "stdbool.h"

    #define INDENT_LENGTH 2
    #define LINE_WIDTH 78

    char word [MAXSTRLEN + 1];
    int level = 0;
    bool new_line = true;
    int cursor_position = 0;


    int yylex(void);
    void yyerror(const char *s);

    void indent();
    void append(char* src);
    void print_word();

%}


%union{
    char s[MAXSTRLEN +1];
}

%start GRAMMAR

%token<s> PI_TAG_BEG PI_TAG_END STAG_BEG ETAG_BEG NAME EQ VALUE
%token<s> TAG_END ETAG_END CHAR S

%type<s> start_tag end_tag word attributes

%%

GRAMMAR : {yyerror( "Empty input source is not valid!"); }
    %empty
    | error
    | document
;

document :
     introduction element
    ;

introduction :
    %empty
    | processing_sequence '\n'
    ;

processing_sequence:
    %empty
    | processing_sequence processing_instruction
    ;


processing_instruction :
    PI_TAG_BEG attributes PI_TAG_END
    {
        indent();
        printf("<? %s %s ?>\n", $1, $2);
        new_line = true;
    }
    ;

attributes :
    %empty
    {
        $$[0] = '\0';
    }
    | attributes NAME EQ VALUE
    {
        strncat($$, " ", MAXSTRLEN);
        strncat($$, $2, MAXSTRLEN);
        strncat($$, "=", MAXSTRLEN);
        strncat($$, $4, MAXSTRLEN);
    }
    ;

element :
    empty_tag
    | pair_of_elements
    ;

empty_tag :
    STAG_BEG ETAG_END
    {
        indent();
        printf("<%s/>\n", $1);
        new_line = true;
    }
    ;

pair_of_elements :
    start_tag content end_tag
    {
        if(strncmp($1, $3, MAXSTRLEN) != 0){
            yyerror("Error: Opening tag does not match closing tag \n");
        }

        if(strlen(word) > 0){
            print_word();
            printf("\n");
        }

        level--;
        indent();
        printf("</%s>\n", $3);
        new_line = true;
    }
    ;

start_tag :
    STAG_BEG TAG_END
    {
        indent();
        printf("<%s>\n", $1);
        level++;
    }
    ;

end_tag :
    ETAG_BEG TAG_END
    ;

content :
    %empty
    | content element
    | content S
    {
        append($2);
    }
    | content word
    | content '\n'
    {
        append("\n");
    }
    ;

word :
    CHAR
    {
        append($1);
    }
    | word CHAR
    {
        append($2);
    }
    ;
%%

int main(void){

    //yydebug = 1;
    yyparse();
    return 0;
}

void yyerror(const char *s){
    printf("Error: %s\n", s);

}

void indent(){
    cursor_position = 0;
    for (int i = 0; i < level * INDENT_LENGTH; i++){
        putchar(' ');
    }
}

void append(char* src){

    strncat(word, src, MAXSTRLEN);

    if(new_line == true){
        indent();
    }
    new_line = false;

    if (level * INDENT_LENGTH + cursor_position + strlen(word) >= LINE_WIDTH){
        if (cursor_position == 0) {
            print_word();
            printf("\n");
            indent();
        }
         else {
            printf("\n");
            indent(level);
        }
    }
    else {
        if (src[0] == ' ' || src[0] == '\t')
        {
            print_word();
        }
         else if (src[0] == '\n') {
            print_word();
            new_line = true;
        }
    }
}

void print_word() {
    printf("%s", word);
    cursor_position += strlen(word);
    word[0] = '\0';
}
