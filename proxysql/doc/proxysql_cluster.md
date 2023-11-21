* * * 

## Este documento tem como objetivo, através de exemplos práticos, demonstrar a criação de snapshots LVM dos discos das máquinas virtuais.

> Snapshots são discos virtuais congelados no tempo; utilizados para backup.

* * * 

### Etapas:

* Verificar o LV (volume lógico) utilizado pela máquina virtual que queremos realizar o snapshot
* Validar se há espaço suficiente
* Criar o snapshot
* Validar snapshot criado

* * *

### Cenários de virtualização:

A máquina virtual pode ou não estar em ambiente com alta disponibilidade via *DRBD*. O processo para criação do snapshot é ligeiramente diferente em cada um dos casos, por isso esta documentação dividirá os dois cenários em procedimentos distintos. 

**Esta informação deve estar clara** na execução do snapshot, e também pode ser validada com o comando `drbd-overview`. **Se o nome da VM for listado (como recurso do DRBD), ela está em alta disponibilidade**; caso contrário, ela é uma máquina *standalone*.

**BASTA SEGUIR APENAS UM DOS DOIS PROCEDIMENTOS!!!**

* Cenário I - Máquina virtual em ambiente *standalone*
* Cenário II - Máquina virtual em ambiente de alta disponibilidade com *DRBD*

* * *
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;
&nbsp;


## Cenário I - Máquina virtual em ambiente *standalone*

#### Passo 1: Descobrir o volume lógico (disco) de origem da máquina virtual

Primeiramente, descubra o nome da VM com o comando `xl list`:

![xl_list.png](MT4-FRS-Take_LVM_Snapshots_images/xl_list.png)


Liste os discos das VMs com o comando `xl list --long | grep pdev_path | grep '/dev/'`, e procure pelo nome da VM:

![pdev_path.png](MT4-FRS-Take_LVM_Snapshots_images/pdev_path.png)

> No padrão FRS, o disco e a VM possuem o mesmo nome

> A VM *K8s_002* está em HA, e por isso não teve seu disco listado

Assim descobrimos a seguinte relação VM/Disco:

|       VM      |           Disco           |
|:-------------:|:-------------------------:|
| **DEV-SS1-DEB10** | /dev/vgDom0/**DEV-SS1-DEB10** |
|  **QA-SS1-DEB10** |  /dev/vgDom0/**QA-SS1-DEB10** |
|  **QA-SS2-DEB10** |  /dev/vgDom0/**QA-SS2-DEB10** |
|    **K8s_002**    |    *VM em HA*    |

* * *

#### Passo 2: Confirmar se há espaço suficiente para o snapshot

**Verifique se o VG possui espaço livre** disponível para a criação do snapshot, com o comando `vgs`, buscando pela opção `VFree` do **VG do disco de origem**. 

> O VG do disco de origem é o nome que se encontra entre `/dev/` e o nome da VM no caso dos exemplos do passo 1, `vgDom0`.

![vgs.png](MT4-FRS-Take_LVM_Snapshots_images/vgs.png)

> Temos cerca de 354G disponíveis no VG `vgDom0` para a criação dos snapshots.

* * * 


#### Passo 3: Criação do snapshot

Crie o snapshot do disco, com o comando `lvcreate -L <tamanho_do_snapshot> -n <nome_do_snapshot> -s <disco_de_origem>`.

> Preencha `<tamanho_do_snapshot>`, `<nome_do_snapshot>` e `<disco_de_origem>` com os valores desejados.

* O parâmetro `<nome_do_snapshot>` é o nome que daremos para identificar de forma única e descritiva, o snapshot que será realizado. Ex: `snap_atualizacao_ss_20200226` 
 

* O parâmetro `<tamanho_do_snapshot>` é o tamanho do snapshot criado. O espaço em disco do snapshot é consumido conforme mudanças são feitas no disco de origem. Ou seja, o snapshot **NÃO PRECISA** ter o tamanho do disco de origem, e sim **um tamanho próximo ao quanto se espera consumir de espaço na GMUD/RDM/CRQ**. Se esperamos uma alteração máxima de 10G no disco de origem, 15G seria um tamanho seguro para esse snapshot.

> O tamanho do snapshot está relacionado ao quanto se espera consumir do disco da VM, e não ao tamanho do disco em si.

* O parâmetro `<disco_de_origem>` é o LV da VM, descoberto no passo 1.

Abaixo exemplo de criação de um snapshot do disco `DEV-SS1-DEB10` chamado `snap_devss1_doc` com `15 GB` de tamanho.

![snap_creation_devss1.png](MT4-FRS-Take_LVM_Snapshots_images/snap_creation_devss1.png)

* * * 

#### Passo 4: Validação do novo snapshot criado

Valide a criação do snapshot com o comando `lvs`:

![snap_validation_standalone.png](MT4-FRS-Take_LVM_Snapshots_images/snap_validation_standalone.png)

Na imagem acima podemos ver que temos um novo LV chamado `snap_devss1_doc`, que referencia o LV `DEV-SS1-DEB10`, e que está consumindo atualmente `8,54%` dos `15G` reservados para ele

* * *

Ao término bem sucedido da GMUD/RDM/CRQ, remova o snapshot com o comando `lvremove`:

### <span style="color: red;">MUITA ATENÇÃO</span> para remover o snapshot, e não disco de origem do snapshot (remover <span style="color: red;">snap_devss1_doc</span> e não `DEV-SS1-DEB10`):


![lvremove2.png](MT4-FRS-Take_LVM_Snapshots_images/lvremove2.png)

&nbsp;
&nbsp;

## Cenário II - Máquina virtual em ambiente de alta disponibilidade com *DRBD*
 
> *As etapas devem ser realizadas tanto no servidor de produção, quanto no de contingência!* 

#### Passo 1: Descobrir o volume lógico (disco) de origem da máquina virtual

Primeiramente, descubra o nome da VM com o comando `xl list`:

![xl_list.png](MT4-FRS-Take_LVM_Snapshots_images/xl_list.png)

Confirme o nome do recurso de replicação do DRBD com o comando `drbd-overview`:

![drbdoverview.png](MT4-FRS-Take_LVM_Snapshots_images/drbdoverview.png)
 
Com o nome do recurso em mãos, **confirme o disco de origem do snapshot** da VM, com o comando `drbdadm sh-md-dev <nome_do_recurso>`:

> Para esta documentação, apenas a VM *K8s_002* está em HA.

![sh-md-dev.png](MT4-FRS-Take_LVM_Snapshots_images/sh-md-dev.png)

Assim descobrimos a seguinte relação VM/HA/Disco:


|       VM      | Recurso DRBD |           Disco           |
|:-------------:|:------------:|:-------------------------:|
| **K8s_002** |    **K8s_002**   | /dev/vgDom0/**K8s_002** |


* * *

#### Passo 2: Confirmar se há espaço suficiente para o snapshot

**Verifique se o VG possui espaço livre** disponível para a criação do snapshot, com o comando `vgs`, buscando pela opção `VFree` do **VG do disco de origem**. 

> O VG do disco de origem é o nome que se encontra entre `/dev/` e o nome da VM no caso dos exemplos do passo 1, `vgDom0`.

![vgs.png](MT4-FRS-Take_LVM_Snapshots_images/vgs.png)

> Temos cerca de 354G disponíveis no VG `vgDom0` para a criação dos snapshots.


* * * 

#### Passo 3: Criação do snapshot

Crie o snapshot do disco, com o comando `lvcreate -L <tamanho_do_snapshot> -n <nome_do_snapshot> -s <disco_de_origem>`. 

**Como a VM está em HA, crie o snapshot também na contingência, seguindo o procedimento discorrido até aqui**

> Preencha `<tamanho_do_snapshot>`, `<nome_do_snapshot>` e `<disco_de_origem>` com os valores desejados.

* O parâmetro `<nome_do_snapshot>` é o nome que daremos para identificar de forma única e descritiva, o snapshot que será realizado. Ex: `snap_atualizacao_ss_20200226` 
 
* O parâmetro `<tamanho_do_snapshot>` é o tamanho do snapshot criado. O espaço em disco do snapshot é consumido conforme mudanças são feitas no disco de origem. Ou seja, o snapshot **NÃO PRECISA** ter o tamanho do disco de origem, e sim **um tamanho próximo ao quanto se espera consumir de espaço na GMUD/RDM/CRQ**. Se esperamos uma alteração máxima de 10G no disco de origem, 15G seria um tamanho seguro para esse snapshot.

> O tamanho do snapshot está relacionado ao quanto se espera consumir do disco da VM, e não ao tamanho do disco em si.

* O parâmetro `<disco_de_origem>` é o LV da VM, descoberto no passo 1.

Abaixo exemplo de criação de um snapshots do disco `K8s_002` chamado `snap_k8s_doc` com `15 GB` de tamanho.

> Também deve ser criado o snapshot no servidor de contingência

![snap_creation_k8s_primary.png](MT4-FRS-Take_LVM_Snapshots_images/snap_creation_k8s_primary.png)



* * * 

#### Passo 4: Validação do novo snapshot criado

Valide a criação do snapshot com o comando `lvs`:

![snap_validation_ha.png](MT4-FRS-Take_LVM_Snapshots_images/snap_validation_ha.png)

Na imagem acima podemos ver que temos um novo LV chamado `snap_k8s_doc`, que referencia o LV `K8s_002`, e que está consumindo atualmente `0,01%` dos `15G` reservados para ele.

* * *

Ao término bem sucedido da GMUD/RDM/CRQ, remova o snapshot com o comando `lvremove`:

### <span style="color: red;">MUITA ATENÇÃO</span> para remover o snapshot, e não disco de origem do snapshot (remover <span style="color: red;">snap_k8s_doc</span> e não `K8s_002`):

![lvremove.png](MT4-FRS-Take_LVM_Snapshots_images/lvremove.png)
