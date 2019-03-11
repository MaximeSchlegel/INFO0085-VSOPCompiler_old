%{
    //TODO relove the Return and display, just return the corresponding symbol
    #include "lexer/header_lexer.h"

    #define YY_DECL extern "C" int yylex()

    YYSTYPE yylval;
    int yycharno = 1, prevTokenLength = 0;

    std::map<std::string, int> reservedId;
    std::string filename;

    std::string strBuffer;
    std::pair<int,int> strStartPosition;
    std::stack<std::pair<int, int>> openedCommentsPosition;
%}

%option noyywrap
%option yylineno

%x INLINECOMMENT
%x MULTILINECOMMENT
%x STR

space           " "
tab             \x09
lf              \x0A
ff              \x0B
cr              \x0C
whitespace      {space}|{tab}
ignored-char    {whitespace}|{ff}|{cr}

bin-digit          0|1
digit              {bin-digit}|[2-9]
hex-digit          {digit}|[a-fA-F]
bin-literal        0b{bin-digit}+
digit-literal      {digit}+
hex-literal        0x{hex-digit}+
integer-literal    {digit-literal}|{hex-literal}|{bin-literal}

lowercase-letter    [a-z]
uppercase-letter    [A-Z]
letter              {lowercase-letter}|{uppercase-letter}

typeId      {uppercase-letter}({letter}|{digit}|_)*
objectId    {lowercase-letter}({letter}|{digit}|_)*


%%
"//"                 { yycharnoRefresh();
                       BEGIN(INLINECOMMENT);
                     }
<INLINECOMMENT>.*    { yycharnoRefresh(); }
<INLINECOMMENT>\n    { yycharnoNewline();
                       BEGIN(INITIAL);}

<INITIAL,MULTILINECOMMENT>"(*"    { yycharnoRefresh();
                                    openedCommentsPosition.emplace(yylineno, yycharno);
                                    BEGIN(MULTILINECOMMENT);
                                  }
<MULTILINECOMMENT>"*)"            { yycharnoRefresh();
                                    openedCommentsPosition.pop();
                                    if (openedCommentsPosition.empty()) { BEGIN(INITIAL); }
                                  }
<MULTILINECOMMENT>([^*(\n])+      { yycharnoRefresh(); }
<MULTILINECOMMENT>\*              { yycharnoRefresh(); }
<MULTILINECOMMENT>\               { yycharnoRefresh(); }
<MULTILINECOMMENT>\n              { yycharnoNewline(); }
<MULTILINECOMMENT><<EOF>>         { yycharnoRefresh();
                                    int errorLine = openedCommentsPosition.top().first, errorChar = openedCommentsPosition.top().second;
                                    return returnAndDisplayError(101, errorLine, errorChar);
                                  }

\x22                           { yycharnoRefresh();
                                 strStartPosition = std::pair<int , int>(yylineno, yycharno);
                                 strBuffer = yytext;
                                 BEGIN(STR);
                               }
<STR>\x22                      { yycharnoRefresh();
                                 strBuffer += yytext;
                                 yylval.strValue = &strBuffer;
                                 BEGIN(INITIAL);
                                 return returnAndDisplayToken(268, strStartPosition.first, strStartPosition.second );
                               }
<STR>\x5C\x0A([ '\x09'])*      { yycharnoNewline();
                                 std::cout << "here";
                                  prevTokenLength = yyleng - 2;
                               }
<STR>\x5Cb                     { yycharnoRefresh();
                                 strBuffer += "\\x08";
                               }
<STR>\x5Ct                     { yycharnoRefresh();
                                 strBuffer += "\\x09";
                               }
<STR>\x5Cn                     { yycharnoRefresh();
                                 strBuffer += "\\x0a";
                               }
<STR>\x5Cr                     { yycharnoRefresh();
                                 strBuffer += "\\x0d";
                               }
<STR>\x5C\x22                  { yycharnoRefresh();
                                 strBuffer += 92;
                                 strBuffer += 34;
                               }
<STR>\x5C\x5C                  { yycharnoRefresh();
                                 strBuffer += 92;
                                 strBuffer += 92;
                               }
<STR>\x5Cx({hex-digit}{2})     { yycharnoRefresh();
                                 std::string s = yytext; s = s.erase(0,2);
                                 int intLit = dehexify(s);
                                 if (intLit == -1) {
                                   return returnAndDisplayError(107, yylineno, yycharno);
                                 }
                                 if (intLit < 32 or intLit == 127) {
                                   strBuffer += "\\x" + s;
                                 } else {
                                   strBuffer += intLit;
                                 }
                               }
<STR>\x5C                      { yycharnoRefresh();
                                 return returnAndDisplayError(106, yylineno, yycharno);
                               }
<STR>\x00                      { yycharnoRefresh();
                                 return returnAndDisplayError(108, yylineno, yycharno);
                               }
<STR>\x0A                      { yycharnoRefresh();
                                 return returnAndDisplayError(109, yylineno-1, yycharno);
                               }
<STR><<EOF>>                   { yycharnoRefresh();
                                 int errorLine = strStartPosition.first, errorChar = strStartPosition.second;
                                 return returnAndDisplayError(101, errorLine, errorChar);
                               }
<STR>.                         { yycharnoRefresh();
                                 strBuffer += yytext;
                               }

{bin-literal}                             { yycharnoRefresh();
                                            std::string s = yytext; s = s.erase(0,2);
                                            int intLit = debinify(s);
                                            if (intLit == -1) {
                                              return returnAndDisplayError(102, yylineno, yycharno);
                                            }
                                            yylval.intValue = intLit;
                                            return returnAndDisplayToken(267);
                                          }
{digit-literal}                           { yycharnoRefresh();
                                            int intLit = dedigify(yytext);
                                            if (intLit == -1) {
                                              return returnAndDisplayError(103, yylineno, yycharno);
                                            }
                                            yylval.intValue = intLit;
                                            return returnAndDisplayToken(267);
                                          }
{hex-literal}                             { yycharnoRefresh();
                                            std::string s = yytext; s = s.erase(0,2);
                                            int intLit = dehexify(s);
                                            if (intLit == -1) {
                                              return returnAndDisplayError(104, yylineno, yycharno);
                                            }
                                            yylval.intValue = intLit;
                                            return returnAndDisplayToken(267);
                                          }
{integer-literal}({objectId}|{typeId})    { yycharnoRefresh();
                                            return returnAndDisplayError(105, yylineno, yycharno);
                                          }

{typeId}    { yycharnoRefresh();
              std::string s = yytext;
              yylval.strValue = &s;
              return returnAndDisplayToken(264);
            }

{objectId}    { yycharnoRefresh();
                std::map<std::string, int>::iterator isReserved;
                isReserved = reservedId.find(yytext);
                if (isReserved != reservedId.end()) {
                  return returnAndDisplayToken(isReserved->second);
                } else {
                  std::string s = yytext;
                  yylval.strValue = &s;
                  return returnAndDisplayToken(282);
                }
              }

"{"    { yycharnoRefresh();
         return returnAndDisplayToken(283);
       }
"}"    { yycharnoRefresh();
         return returnAndDisplayToken(284);
       }
"("    { yycharnoRefresh();
         return returnAndDisplayToken(285);
       }
")"    { yycharnoRefresh();
         return returnAndDisplayToken(286);
       }
":"    { yycharnoRefresh();
         return returnAndDisplayToken(287);
       }
";"    { yycharnoRefresh();
         return returnAndDisplayToken(288);
       }
","    { yycharnoRefresh();
         return returnAndDisplayToken(289);
       }
"+"    { yycharnoRefresh();
         return returnAndDisplayToken(290);
       }
"-"    { yycharnoRefresh();
         return returnAndDisplayToken(291);
       }
"*"    { yycharnoRefresh();
         return returnAndDisplayToken(292);
       }
"/"    { yycharnoRefresh();
         return returnAndDisplayToken(293);
       }
"^"    { yycharnoRefresh();
         return returnAndDisplayToken(294);
       }
"."    { yycharnoRefresh();
         return returnAndDisplayToken(295);
       }
"="    { yycharnoRefresh();
         return returnAndDisplayToken(296);
       }
"<"    { yycharnoRefresh();
         return returnAndDisplayToken(297);
       }
"<="   { yycharnoRefresh();
         return returnAndDisplayToken(298);
       }
"<-"   { yycharnoRefresh();
         return returnAndDisplayToken(299);
       }

{ignored-char}+    { yycharnoRefresh(); }
{lf}+              { yycharnoNewline(); }
<<EOF>>            { yycharnoRefresh();
                     return returnAndDisplayToken(258, yylineno, yycharno, false);
                   }
.                  { yycharnoRefresh();
                     return returnAndDisplayError(110, yylineno, yycharno);
                   }


%%
