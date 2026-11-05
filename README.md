### Escuela Colombiana de Ingeniería
### Arquitecturas de Software - ARSW

## Escalamiento en Azure con Maquinas Virtuales, Sacale Sets y Service Plans

### Dependencias
* Cree una cuenta gratuita dentro de Azure. Para hacerlo puede guiarse de esta [documentación](https://azure.microsoft.com/es-es/free/students/). Al hacerlo usted contará con $100 USD para gastar durante 12 meses.
Antes de iniciar con el laboratorio, revise la siguiente documentación sobre las [Azure Functions](https://www.c-sharpcorner.com/article/an-overview-of-azure-functions/)

### Parte 0 - Entendiendo el escenario de calidad

Adjunto a este laboratorio usted podrá encontrar una aplicación totalmente desarrollada que tiene como objetivo calcular el enésimo valor de la secuencia de Fibonnaci.

**Escalabilidad**
Cuando un conjunto de usuarios consulta un enésimo número (superior a 1000000) de la secuencia de Fibonacci de forma concurrente y el sistema se encuentra bajo condiciones normales de operación, todas las peticiones deben ser respondidas y el consumo de CPU del sistema no puede superar el 70%.

### Escalabilidad Serverless (Functions)

1. Cree una Function App tal cual como se muestra en las  imagenes.

![](images/part3/part3-function-config.png)

![](images/part3/part3-function-configii.png)

2. Instale la extensión de **Azure Functions** para Visual Studio Code.

![](images/part3/part3-install-extension.png)

3. Despliegue la Function de Fibonacci a Azure usando Visual Studio Code. La primera vez que lo haga se le va a pedir autenticarse, siga las instrucciones.

![](images/part3/part3-deploy-function-1.png)

![](images/part3/part3-deploy-function-2.png)

4. Dirijase al portal de Azure y pruebe la function.

![](images/part3/part3-test-function.png)

5. Modifique la coleción de POSTMAN con NEWMAN de tal forma que pueda enviar 10 peticiones concurrentes. Verifique los resultados y presente un informe.

6. Cree una nueva Function que resuleva el problema de Fibonacci pero esta vez utilice un enfoque recursivo con memoization. Pruebe la función varias veces, después no haga nada por al menos 5 minutos. Pruebe la función de nuevo con los valores anteriores. ¿Cuál es el comportamiento?.

**Preguntas**

## ¿Qué es serverless?
Es un modelo donde no te preocupas por servidores: subes tu código y Azure se encarga de levantar, escalar y apagar la infraestructura. El código corre solo cuando algo lo dispara (una petición HTTP, un timer, una cola…), escala solo y pagas por lo que usas. Ojo: las instancias son **efímeras y sin estado**.
 
## ¿Qué es el runtime y qué implica seleccionarlo?
Es el lenguaje y su versión (Node.js, .NET, Java, Python, PowerShell) sobre el que corren las funciones. Elegirlo implica:
- Todas las funciones de la app tienen que estar en ese lenguaje.
- Define qué sistema operativo y qué planes puedes usar (por ejemplo, Flex Consumption solo funciona en Linux).
- Afecta el cold start y el consumo de memoria, o sea, el costo.
- Cambiarlo después no es fácil; casi siempre toca recrear la app.
## ¿Por qué se necesita un Storage Account?
Porque el host de Functions no funciona sin él (se conecta por `AzureWebJobsStorage`). Ahí se guardan:
- El código y la configuración (Azure Files o Blob, según el plan).
- Las llaves de las funciones y el estado de los triggers/bindings.
- Las colas y tablas para reintentos y para Durable Functions.
- Los leases con los que se coordina el escalado entre instancias.
Si borras el storage, la app deja de funcionar.
 
## Tipos de planes
 
| Plan | En corto | Pro | Contra |
|---|---|---|---|
| **Consumption** | Pago por ejecución, escala a 0 | Baratísimo con poco tráfico, con free grant | Legacy, cold starts, sin VNet, timeout máx. de 10 min |
| **Flex Consumption** | Consumption mejorado | Escala rápido, eliges la memoria, tiene VNet e instancias *always ready*, sin límite de tiempo | Solo Linux, una app por plan, el GB-s es más caro |
| **Premium** | Instancias pre-calentadas | Sin cold start, con VNet, más potencia | Siempre hay ≥1 instancia encendida, así que es caro (~$175/mes EP1) |
| **Dedicated** (App Service) | Corre en VMs de un App Service Plan | Costo predecible, puedes reutilizar un plan que ya pagas, Always On | Pagas aunque no haya tráfico, escala más lento |
 
## ¿Por qué falla la memoization?
1. **La caché vive en RAM.** Si la función se queda quieta unos minutos, Azure apaga la instancia y la caché se pierde. Por eso, después de esperar 5 min, la misma consulta vuelve a tardar igual que la primera vez.
2. **Cada instancia tiene su propia caché.** Con peticiones concurrentes, Azure puede levantar varias instancias y ninguna comparte lo que calculó la otra.
3. **La recursión con n > 1.000.000 revienta el stack** (`Maximum call stack size exceeded`). Además, guardar un millón de BigInts consume muchísima memoria.
Para arreglarlo habría que usar una caché externa (Redis/Table Storage) y un algoritmo iterativo.
 
## ¿Cómo se factura?
- **Consumption:** se cobra por número de ejecuciones + GB-s (memoria × tiempo). Trae gratis 1M de ejecuciones y 400.000 GB-s al mes por suscripción. Lo mínimo que se cobra por ejecución es 100 ms y 128 MB.
- **Flex Consumption:** igual (ejecuciones + GB-s), pero el free grant es de 250.000 ejecuciones y 100.000 GB-s. Si tienes instancias *always ready*, pagas además una tarifa base por tenerlas encendidas.
- **Premium:** se paga por vCPU-s y GB-s de las instancias encendidas, y como siempre hay mínimo una, hay un costo fijo.
- **Dedicated:** pagas el App Service Plan, sin importar cuántas ejecuciones haya.
El Storage Account y Application Insights se cobran aparte.
* Informe
