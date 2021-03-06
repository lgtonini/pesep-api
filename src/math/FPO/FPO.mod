# Conjuntos
set BUS;    # Barras
set BRANCH within {1..4000} cross BUS cross BUS; # Linhas (Guarda os índices e barra de partida e chegada)

# Arquivo de solução
option solver '../../../../ampl/minos';				#Escolhe o MINOS como solver

# Dados das barras
param bus_type       {BUS};       # Tipo (3-Slack 2-PV 0-PQ)
param bus_name       {BUS} symbolic;  # Nome 
param bus_voltage0   {BUS};       # Tensão inicial: As PQs serão 1
param bus_angle0     {BUS};       # Ângulo inicial: As PQs e PVs serão 0
param bus_p_gen     {BUS};          # Potência ativa do gerador
param bus_q_gen      {BUS};       # Potência reativa do gerador
param bus_q_min      {BUS};       # Potência reativa mínima
param bus_q_max      {BUS};       # Potência reativa máxima
param bus_p_load     {BUS};       # Potência ativa da carga
param bus_q_load     {BUS};       # Potência reativa da carga
param bus_p_gen_min  {BUS};       # Potência ativa mínima no gerador
param bus_p_gen_max  {BUS};       # Potência ativa máxima no gerador
param bus_q_shunt    {BUS};       # Potência reativa do shunt em cada barra
param bus_x        {BUS};         # Reatância da barra

# dados das linhas

param branch_type    {BRANCH};      # Índice
param branch_r       {BRANCH};      # Resistência 
param branch_x       {BRANCH};      # Indutância
param branch_tap     {BRANCH};      # Razão de transformação
param branch_def     {BRANCH};      # Angulo de defasamento
param branch_x_traf  {BRANCH};        # Impedância do transformador
param branch_res_zero{BRANCH};        # Resistência da linha de seguência zero
param branch_traf  {BRANCH};      # Tipo de transformador: 1-DY e 2-YY
param branch_g       {(l,k,m) in BRANCH} := branch_r[l,k,m]/(branch_r[l,k,m]^2+branch_x[l,k,m]^2); # Condutância
param branch_b       {(l,k,m) in BRANCH} :=-(branch_x[l,k,m]+branch_x_traf[l,k,m])/(branch_r[l,k,m]^2+(branch_x[l,k,m]+branch_x_traf[l,k,m])^2); # Susceptância
param branch_b_zero  {(l,k,m) in BRANCH} :=-(branch_x[l,k,m]+branch_x_traf[l,k,m]+branch_res_zero[l,k,m])/(branch_r[l,k,m]^2+(branch_x[l,k,m]+branch_x_traf[l,k,m]+branch_res_zero[l,k,m])^2); # Susceptância de sequência zero


# dados gerais

param Sbase; #Potência nominal

# Variáveis

var bus_voltage {i in BUS};   # Tensão nas barras
var bus_angle   {i in BUS};   # Ângulo nas barras
var dummy;

# Variáveis auxiliares

var p_g {BUS};    # Potência ativa transmitida nas linhas
var q_g {BUS};    # Potência reativa transmitida nas linhas

var p_d {BRANCH}; # Fluxo direto ativo
var q_d {BRANCH}; # fluxo direto reativo
var p_r {BRANCH}; # fluxo inverso ativo
var q_r {BRANCH}; # fluxo inverso reativo

# matriz YBUS

set YBUS := setof{i in BUS} (i,i) union 
setof {(l,k,m) in BRANCH} (k,m) union
setof {(l,k,m) in BRANCH} (m,k);

param G{(k,m) in YBUS} =    # Monta o vetor de condutância para o fluxo de potência
if(k == m) then (sum{(l,k,i) in BRANCH} branch_g[l,k,i]*branch_tap[l,k,i]^2
                                + sum{(l,i,k) in BRANCH} branch_g[l,i,k])
else if(k != m) then (sum{(l,k,m) in BRANCH} (-branch_g[l,k,m]*cos(branch_def[l,k,m])-branch_b[l,k,m]*sin(branch_def[l,k,m]))*branch_tap[l,k,m]
                     +sum{(l,m,k) in BRANCH} (-branch_g[l,m,k]*cos(branch_def[l,m,k])+branch_b[l,m,k]*sin(branch_def[l,m,k]))*branch_tap[l,m,k]);
 
param B{(k,m) in YBUS} =    # Monta o vetor de susceptância para o fluxo de potência
if(k == m) then (sum{(l,k,i) in BRANCH} (branch_b[l,k,i]*branch_tap[l,k,i]^2)
                                + sum{(l,i,k) in BRANCH} (branch_b[l,i,k])) 
else if(k != m) then (sum{(l,k,m) in BRANCH} (branch_g[l,k,m]*sin(branch_def[l,k,m])-branch_b[l,k,m]*cos(branch_def[l,k,m]))*branch_tap[l,k,m]
                     +sum{(l,m,k) in BRANCH} (-branch_g[l,m,k]*sin(branch_def[l,m,k])-branch_b[l,m,k]*cos(branch_def[l,m,k]))*branch_tap[l,m,k]);

param B_aux{(k,m) in YBUS} =    # Monta o vetor de susceptância auxiliar para o fluxo de potência
if(k == m) then (sum{(l,k,i) in BRANCH} (branch_b[l,k,i]*branch_tap[l,k,i]^2)
                                + sum{(l,i,k) in BRANCH} (branch_b[l,i,k])-bus_x[k]) 
else if(k != m) then (sum{(l,k,m) in BRANCH} (branch_g[l,k,m]*sin(branch_def[l,k,m])-branch_b[l,k,m]*cos(branch_def[l,k,m]))*branch_tap[l,k,m]
                     +sum{(l,m,k) in BRANCH} (-branch_g[l,m,k]*sin(branch_def[l,m,k])-branch_b[l,m,k]*cos(branch_def[l,m,k]))*branch_tap[l,m,k]);

param B_zero{(k,m) in YBUS} =   # Monta o vetor de susceptância para o fluxo de potência
if(k == m) then (sum{(l,k,i) in BRANCH} (branch_b_zero[l,k,i]*branch_tap[l,k,i]^2)
                                + sum{(l,i,k) in BRANCH} (branch_b_zero[l,i,k])-bus_x[k])
else if(k != m) then (sum{(l,k,m) in BRANCH} (branch_g[l,k,m]*sin(branch_def[l,k,m])-branch_b_zero[l,k,m]*cos(branch_def[l,k,m]))*branch_tap[l,k,m]
                     +sum{(l,m,k) in BRANCH} (-branch_g[l,m,k]*sin(branch_def[l,m,k])-branch_b_zero[l,m,k]*cos(branch_def[l,m,k]))*branch_tap[l,m,k]);

# Função objetivo

minimize dummy_minimization : dummy;

# restrições

subject to p_load {k in BUS : bus_type[k] == 0}:
   bus_p_gen[k] - bus_p_load[k] - sum{(k,m) in YBUS} (bus_voltage[k]*bus_voltage[m]*
                          (G[k,m]*cos(bus_angle[k]-bus_angle[m])+B[k,m]*sin(bus_angle[k]-bus_angle[m]))) = 0;

   subject to q_load {k in BUS : bus_type[k] == 0}: 
   bus_q_gen[k] + bus_q_shunt[k] - bus_q_load[k] - sum{(k,m) in YBUS} (bus_voltage[k]*bus_voltage[m]*
                          (G[k,m]*sin(bus_angle[k]-bus_angle[m])-B[k,m]*cos(bus_angle[k]-bus_angle[m]))) = 0;

subject to q_inj {k in BUS : bus_type[k] == 2 || bus_type[k] == 3}:
   bus_q_min[k] <= - bus_q_shunt[k] + bus_q_load[k] + sum{(k,m) in YBUS} (bus_voltage[k]*bus_voltage[m]*
                (G[k,m]*sin(bus_angle[k]-bus_angle[m])-B[k,m]*cos(bus_angle[k]-bus_angle[m]))) <= bus_q_max[k];

   subject to p_inj {k in BUS : bus_type[k] == 2 || bus_type[k] == 3}:
   bus_p_gen_min[k] <= bus_p_load[k] + sum{(k,m) in YBUS} (bus_voltage[k]*bus_voltage[m]*
               (G[k,m]*cos(bus_angle[k]-bus_angle[m])+B[k,m]*sin(bus_angle[k]-bus_angle[m]))) <= bus_p_gen_max[k];

subject to p_inj_pos {k in BUS : bus_type[k] == 2 || bus_type[k] == 3}:
   bus_p_load[k] + sum{(k,m) in YBUS} (bus_voltage[k]*bus_voltage[m]*
               (G[k,m]*cos(bus_angle[k]-bus_angle[m])+B[k,m]*sin(bus_angle[k]-bus_angle[m]))) >= 1e-15;

subject to bus_voltate_limits {i in BUS}:
   0.9 <= bus_voltage[i] <= 1.1;

subject to dummy_definition:
	dummy = 0;


# Carregamento dos dados
data dados.dat;

# Escalamento e inicialização de dados

for{i in BUS} { # Torna as tensões e ângulos da barra PQ em 1 e 0
	let bus_voltage[i] := 1;
   let bus_angle[i] := 0;
  };

for{i in BUS} { # Coloca as potências em pu
   let bus_p_gen[i] := bus_p_gen[i]/Sbase;
   let bus_q_gen[i] := bus_q_gen[i]/Sbase;
   let bus_q_min[i] := bus_q_min[i]/Sbase;
   let bus_q_max[i] := bus_q_max[i]/Sbase;
   let bus_p_load[i] := bus_p_load[i]/Sbase;
   let bus_q_load[i] := bus_q_load[i]/Sbase;
   let bus_p_gen_min[i] := bus_p_gen_min[i]/Sbase;
   let bus_p_gen_max[i] := bus_p_gen_max[i]/Sbase;

  };

# Coloca os ângulos em radianos
for{(l,k,m) in BRANCH} {                
   let branch_def[l,k,m] := -branch_def[l,k,m]*3.14159/180; 
  };
for {i in BUS }{
    let bus_angle[i] := bus_angle[i]*3.14/180;
  }

# Fixação das variáveis

fix {i in BUS : bus_type[i] == 3} bus_angle[i] := bus_angle0[i]; 		                      # Fixa o angulo da barra Slack
fix {i in BUS : bus_type[i] == 3 || bus_type[i] == 2} bus_voltage[i] := bus_voltage0[i]; 	# Fixa a tensão da barra Slack e PV


option minos_options " timing=1 summary_file = 6 superbasics_limit = 500 major_iterations = 300 meminc=2.64";
option loqo_options "sigfig 0 timing=1 iterlim=200 verbose=1";
option lancelot_options "timing=1";
option snopt_options " superbasics_limit = 1000 timing=1";
solve dummy_minimization;

# Calcula geração de potência ativa e reativa

  for{k in BUS : bus_type[k] ==  3} { 
    let p_g[k]  := bus_p_load[k] + sum{(k,m) in YBUS} (bus_voltage[k]*bus_voltage[m]*
                   (G[k,m]*cos(bus_angle[k]-bus_angle[m])+B[k,m]*sin(bus_angle[k]-bus_angle[m])));

    let q_g[k]  := bus_q_load[k] + sum{(k,m) in YBUS} (bus_voltage[k]*bus_voltage[m]*
                   (G[k,m]*sin(bus_angle[k]-bus_angle[m])-B[k,m]*cos(bus_angle[k]-bus_angle[m])));
  }

  for{k in BUS : bus_type[k] ==  2} { 
    let p_g[k] := bus_p_gen[k];
  }

    for{k in BUS : bus_type[k] ==  2} { 
    let q_g[k]  := bus_q_load[k] + sum{(k,m) in YBUS} (bus_voltage[k]*bus_voltage[m]*
                   (G[k,m]*sin(bus_angle[k]-bus_angle[m])-B[k,m]*cos(bus_angle[k]-bus_angle[m])));
  }

# Calcula os fluxos diretos e inversos de potência ativa e reativa

for{(l,k,m) in BRANCH} {

  let p_d[l,k,m] := branch_g[l,k,m]*bus_voltage[k]^2*branch_tap[l,k,m]^2 
  -branch_g[l,k,m]*bus_voltage[k]*bus_voltage[m]*branch_tap[l,k,m]*cos(bus_angle[k]-bus_angle[m]+branch_def[l,k,m])
  -branch_b[l,k,m]*bus_voltage[k]*bus_voltage[m]*branch_tap[l,k,m]*sin(bus_angle[k]-bus_angle[m]+branch_def[l,k,m]);

  let q_d[l,k,m] :=-(branch_b[l,k,m])*bus_voltage[k]^2*branch_tap[l,k,m]^2 
  -branch_g[l,k,m]*bus_voltage[k]*bus_voltage[m]*branch_tap[l,k,m]*sin(bus_angle[k]-bus_angle[m]+branch_def[l,k,m])
  +branch_b[l,k,m]*bus_voltage[k]*bus_voltage[m]*branch_tap[l,k,m]*cos(bus_angle[k]-bus_angle[m]+branch_def[l,k,m]);

  let p_r[l,k,m] := branch_g[l,k,m]*bus_voltage[m]^2 
  -branch_g[l,k,m]*bus_voltage[k]*bus_voltage[m]*branch_tap[l,k,m]*cos(bus_angle[k]-bus_angle[m]+branch_def[l,k,m])
  +branch_b[l,k,m]*bus_voltage[k]*bus_voltage[m]*branch_tap[l,k,m]*sin(bus_angle[k]-bus_angle[m]+branch_def[l,k,m]);

  let q_r[l,k,m] :=-(branch_b[l,k,m])*bus_voltage[m]^2 
  +branch_g[l,k,m]*bus_voltage[k]*bus_voltage[m]*branch_tap[l,k,m]*sin(bus_angle[k]-bus_angle[m]+branch_def[l,k,m])
  +branch_b[l,k,m]*bus_voltage[k]*bus_voltage[m]*branch_tap[l,k,m]*cos(bus_angle[k]-bus_angle[m]+branch_def[l,k,m]);
}

# Gera o arquivo de saída

  printf "id_barra,nome,tensao_0,angulo_0,pGerada,qGerada,pCarga,qCarga,para,pFluxo,qFluxo\n" > fluxo.csv;
  for{i in BUS} {
  printf "%d,%s,%f,%f,%f,%f,%f,%f,,,,\n", i, bus_name[i], bus_voltage[ i], bus_angle[i]*180/3.14159,
    p_g[i]*Sbase, q_g[i]*Sbase, bus_p_load[i]*Sbase, bus_q_load[i]*Sbase > fluxo.csv;
    
      for{(l,i,m) in BRANCH} {
      printf ",,,,,,,%s,%d,%f,%f\n","", m , p_d[l,i,m]*Sbase, q_d[l,i,m]*Sbase > fluxo.csv;
    }

    for{(l,k,i) in BRANCH} {
      printf ",,,,,,,%s,%d,%f,%f\n","", k, p_r[l,k,i]*Sbase, q_r[l,k,i]*Sbase > fluxo.csv;
    }
  }

# Gera o arquivo de barra para o Curto Circuito

  for{i in BUS} {
  printf "%f ", bus_voltage[i], bus_angle[i]*180/3.14159 > tensao.txt;
  }

  for{i in BUS} {
  printf "%f ", bus_angle[i]*180/3.14159 > angulo.txt;
  }

# Gera o arquivo da matriz de susceptâncias para o Curto Circuito
  for {(k,m) in YBUS }{
    printf "%f ", B_aux[k,m] > sus.txt;
  }

# Gera o arquivo da matriz de susceptâncias para o Curto Circuito
  for {(k,m) in YBUS }{
    printf "%f ", B_zero[k,m] > sus_zero.txt;
  }

# Gera o arquivo da coluna para o Curto Circuito
  for {(k,m) in YBUS }{
    printf "%d ", k > coluna.txt;
  }

  # Gera o arquivo da linha para o Curto Circuito
  for {(k,m) in YBUS }{
    printf "%d ", m > linha.txt;
  }

# Gera o arquivo da matriz de susceptâncias para o Curto Circuito
  for {(l,k,m) in BRANCH }{
    printf "%f ", branch_x[l,k,m] > x_linha.txt;
  }

# Gera o arquivo das impedâncias dos transformadores para o Curto Circuito mono e bifásico
  for {(l,k,m) in BRANCH }{
    printf "%f ", branch_x_traf[l,k,m] > x_linha_traf.txt;
  }

  # Gera o arquivo das impedâncias dos transformadores para o Curto Circuito mono e bifásico
  for {(l,k,m) in BRANCH}{
    printf "%d ", branch_traf[l,k,m] > tipo_traf.txt;
  }

  # Gera o arquivo das impedâncias dos transformadores para o Curto Circuito mono e bifásico
  for {(l,k,m) in BRANCH}{
    printf "%d ", m > local_tipo_traf.txt;
  }

# Gera o arquivo de saída

  printf "Barra;Nome;Tensão;Angulo;Pgerada;Qgerada;Pcarga;Qcarga;Para;P_fluxo;Q_fluxo\n" > saida.csv;
  for{i in BUS} {
  printf "%d;%s;%f;%f;%f;%f;%f;%f\n", i, bus_name[i], bus_voltage[i], bus_angle[i]*180/3.14159,
    p_g[i]*Sbase, q_g[i]*Sbase, bus_p_load[i]*Sbase, bus_q_load[i]*Sbase> saida.csv;
    for{(l,i,m) in BRANCH} {
      printf ";;;;;;;%s;%d;%f;%f\n","", m , p_d[l,i,m]*Sbase, q_d[l,i,m]*Sbase > saida.csv;
    }

    for{(l,k,i) in BRANCH} {
      printf ";;;;;;;%s;%d;%f;%f\n","", k, p_r[l,k,i]*Sbase, q_r[l,k,i]*Sbase > saida.csv;
    }
  }







