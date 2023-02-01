# Sistemas Operativos
### Ano Letivo: 2022/23
### **Nota: 19**
## 1º Projeto - Taxas de Leitura/Escrita de processos em bash
> Objetivo:</br>
> Desenvolver um *script* em **bash** para obter estatísticas sobre as leituras e escritas que os processos estão a efetuar. Esta ferramente permite visualizar o número total de bytes de I/O que um processo leu/escreveu e também a taxa de leitura/escrita correspondente aos últimos *s* segundos para uma seleção de processos (o valor de *s* é passado como parâmetro). <br/>
> Os parâmetros usados devem ser sempre validados. <br/>
>
> Opções a desenvolver:
> - -c: Permite, através de uma expressão regular, filtrar a seleção de processos pelo seu nome.
> - -u: Visualizar a seleção de processos pelo nome de utilizador.
> - -s: Ver os processos que iniciaram a sua execução **após** a data inserida como parâmetro neste filtro.
> - -e: Ver os processos que iniciaram a sua execução **antes** da data inserida como parâmetro neste filtro.
> - -m: Através de um PID mínimo passado como parâmetro, filtrar os processos com PID maior.
> - -M: Através de um PID máximo passado como parâmetro, mostrar apenas os processos com PID menor.
> - -w: Organizar a tabela em função da coluna RATEW, correspondente aos valores de escrita.
> - -r: Mostrar a tabela em ordem contrária (crescente) à ordem default.

#### Projeto feito por [@dianarrmiranda](https://github.com/dianarrmiranda) e [@jnluis](https://github.com/jnluis)
