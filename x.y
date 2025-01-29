%{
    #include "stdio.h"
    #include "string.h"
    #include "defs.h"
    #include "stdbool.h"

    #define INDENT_LENGTH 5
    #define LINE_WIDTH 78

    int level = 0;
    bool new_word = true;

    char word [MAXSTRLEN + 1];
    int current_line_length = 0;

    void indent(int level);
    int yylex(void);
    void yyerror(const char *s);

    void append(char* src);
    void print_word();

%}


%union {
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
    optional_white_space introduction element optional_white_space
    ;

introduction :
    %empty
    | processing_sequence '\n'
    ;

processing_sequence:
    %empty
    | processing_instruction processing_sequence
    ;


processing_instruction :
    PI_TAG_BEG attributes PI_TAG_END
    {
        indent(level);
        printf("<? %s %s ?>\n", $1, $2);
        new_word = true;
    }
    ;

element :
    empty_tag
    | pair_of_elements
    ;

empty_tag :
    STAG_BEG ETAG_END
    {
        indent(level);
        printf("<%s/>\n", $1);
        new_word = true;
    }
    ;

pair_of_elements :
    start_tag content end_tag
    {
        if(strncmp($1, $3, MAXSTRLEN) != 0) {
            yyerror("Error: Opening tag does not match closing tag \n");
        }

        if(strlen(word) > 0) {
            print_word();
            printf("\n");
        }

        level--;
        indent(level);
        printf("</%s>\n", $3);
        new_word = true;
    }

    ;

start_tag :
    STAG_BEG TAG_END
    {
        indent(level);
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
      append(" ");
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



white_space :
    S
    | '\n'
    ;

optional_white_space :
    %empty
    | white_space optional_white_space
    ;
%%

int main(void) {

    //yydebug = 1;
    yyparse();
    return 0;
}

void yyerror(const char *s) {
    printf("Error: %s\n", s);

}

void indent(int level) {
    current_line_length = 0;
    int i;
    for (i = 0; i < level * INDENT_LENGTH; i++) {
        putchar(' ');
    }
}

void append(char* src) {

    strncat(word, src, MAXSTRLEN);

    if(new_word == true) {
        indent(level);
    }
    new_word = false;
    if (level * INDENT_LENGTH + current_line_length + strlen(word) >= LINE_WIDTH) {
        if (current_line_length == 0) {
            print_word();
            printf("\n");
            indent(level);
        } else {
            printf("\n");
            indent(level);
        }
    } else {
        if (src[0] == ' ') {
            print_word();
        } else if (src[0] == '\n') {
            print_word();
            new_word = true;
        }
    }
}

void print_word() {
   printf("%s", word);
    current_line_length += strlen(word);
    word[0] = '\0';
}
