

use Math;  // Chapel's built-in Math module

/* Import your own module for knn
import knn;
*/


// Conditional Compilation
// Conditional Compilation
// Conditional Compilation
config const SPECIALIZED = 1;  // You can set this to 1 or 0 as needed
config const K = 3;            // Set K to your desired value

if SPECIALIZED == 1 && K == 3 {
    // Define the SWAP procedure as a generic function using a single type parameter 'T'
    proc swap(a, b: ?T) {
        var temp = a;
        a = b;
        b = temp;
    }
}


/**
*  Get the 3 nearest points.
*  This version stores the 3 nearest points in the first 3 positions of dist_point
*/

// Define the BestPoint record (assuming swap is already defined elsewhere)
record BestPoint {
    var distance: real;        // Assuming 'real' for the distance type
    var classification_id: int;  // Assuming classification_id is an integer
};

// Select the 3 nearest points and store them in dist_points
proc select_3_nearest(dist_points: [1..?] BestPoint, num_points: int) {
    var md1, md2, md3, mdaux: real;
    var di1, di2, di3, diaux: int;

    // Initialize the first 3 points
    md1 = dist_points[1].distance;
    di1 = 1;
    md2 = dist_points[2].distance;
    di2 = 2;
    md3 = dist_points[3].distance;
    di3 = 3;
    
    // Sorting the first 3 points
    if md1 > md2 {
        swap(md1, md2);
        swap(di1, di2);
    } 
    if md2 > md3 {
        swap(md2, md3);
        swap(di2, di3);
    }
    if md1 > md2 {
        swap(md1, md2);
        swap(di1, di2);
    }

    // Loop over the remaining points
    for i in 4..num_points {
        mdaux = dist_points[i].distance;
        diaux = i;

        if mdaux < md1 {
            md3 = md2; di3 = di2;
            md2 = md1; di2 = di1;
            md1 = mdaux; di1 = diaux;
        } else if mdaux < md2 {
            md3 = md2; di3 = di2;
            md2 = mdaux; di2 = diaux;
        } else if mdaux < md3 {
            md3 = mdaux; di3 = diaux;
        }
    }

    // Update the dist_points with the 3 nearest points
    dist_points[1].distance = dist_points[di1].distance;
    dist_points[1].classification_id = dist_points[di1].classification_id;

    dist_points[2].distance = dist_points[di2].distance;
    dist_points[2].classification_id = dist_points[di2].classification_id;

    dist_points[3].distance = dist_points[di3].distance;
    dist_points[3].classification_id = dist_points[di3].classification_id;
}



// Ensure this is defined somewhere in your code:
type CLASS_ID_TYPE = int; // or another appropriate type

// The function to determine the majority vote among 3 best points
proc plurality_voting_3(best_points: [1..3] BestPoint): CLASS_ID_TYPE {
  const ids0 = best_points[1].classification_id;
  const ids1 = best_points[2].classification_id;
  const ids2 = best_points[3].classification_id;

  if ids0 == ids2 then
    return ids0;
  else if ids1 == ids2 then
    return ids1;
  else
    return ids0;
}


proc copy_3_nearest(dist_points: [1..3] BestPoint, best_points: [1..3] BestPoint) {
  for i in 1..3 {
    best_points[i].classification_id = dist_points[i].classification_id;
    best_points[i].distance = dist_points[i].distance;
  }
}






type DATA_TYPE = real; // adjust to real(32) if using float
param NUM_FEATURES = 3; // set this based on your dataset


record Point {
  var features: [0..#NUM_FEATURES] DATA_TYPE;
  var classification_id: int; // or use CLASS_ID_TYPE if defined
}

proc get_3_NN(new_point: Point,
              known_points: [] Point,
              num_points: int,
              best_points: [1..3] BestPoint,
              num_features: int) {

  // Chapel manages memory automatically, so we simply declare the array
  var dist_points: [0..#num_points] BestPoint;

  for i in 0..#num_points {
    var distance: real = 0.0;

    // Euclidean distance
    for j in 0..<num_features {
      const diff = new_point.features[j] - known_points[i].features[j];
      distance += diff * diff;
    }

    // Optional square root, based on your settings (adjust logic as needed)
    distance = sqrt(distance);

    dist_points[i].classification_id = known_points[i].classification_id;
    dist_points[i].distance = distance;
  }

  // Select and copy the 3 nearest neighbors
  select_3_nearest(dist_points, num_points);
  copy_3_nearest(dist_points, best_points);
}

/*
* Classify a given Point (instance).
* It returns the classified class ID.
*/

proc knn_classifyinstance_3(new_point: Point,
                             known_points: [] Point,
                             num_points: int,
                             num_features: int): CLASS_ID_TYPE {

  // Array to hold the 3 nearest neighbors
  var best_points: [1..3] BestPoint;

  // Compute distances and select 3 nearest neighbors
  get_3_NN(new_point, known_points, num_points, best_points, num_features);

  // Use plurality voting to classify the new point
  const classID = plurality_voting_3(best_points);

  return classID;
}

/**
*  Copy the top k nearest points (first k elements of dist_points)
*  to a data structure (best_points) with k points
*/

// Define the procedure to copy the k nearest points
proc copy_k_nearest(dist_points: [0..k-1] BestPoint, best_points: [0..k-1] BestPoint, k: int) {
  // We only need the top k minimum distances
  for i in 0..k-1 {
    best_points[i].classification_id = dist_points[i].classification_id;
    best_points[i].distance = dist_points[i].distance;
  }
}

/**
*  Get the k nearest points.
*  This version stores the k nearest points in the first k positions of dist_point
*/


proc select_k_nearest(ref dist_points: [] BestPoint, num_points: int, k: int) {


  var min_distance, distance_i: real;
  var class_id_1: int;
  var idx: int;


// Loop sobre os primeiros k elementos
  for i in 0..k-1 {
    min_distance = dist_points[i].distance;
    idx = i;  // Usando 'idx' em vez de 'index'

    // Loop para encontrar a distância mínima nos pontos restantes
    for j in i+1..num_points-1 {
      if dist_points[j].distance < min_distance {
        min_distance = dist_points[j].distance;
        idx = j;  // Usando 'idx' em vez de 'index'
      }
    }

    // Se uma nova distância mínima for encontrada, troca os elementos
    if idx != i {  // Usando 'idx' aqui também
      distance_i = dist_points[idx].distance;
      class_id_1 = dist_points[idx].classification_id;

      // Troca as distâncias e ids de classificação
      dist_points[idx].distance = dist_points[i].distance;
      dist_points[idx].classification_id = dist_points[i].classification_id;

      dist_points[i].distance = distance_i;
      dist_points[i].classification_id = class_id_1;
    }
  }
}

/*
* Main kNN function.
* It calculates the distances and calculates the nearest k points.
*/


config const USE_SQRT = 1;
config const MATH_TYPE = 1;
config const DT = 2;
config const DIST_METHOD = 1; // ou 2, dependendo da distância desejada
config const DIMEM = 0; // permite que você altere o valor de DIMEM na hora de compilar



proc get_k_NN(new_point: Point, known_points: [] Point, num_points: int,
              best_points: [] BestPoint, k: int, num_features: int) {
                
              //printf("num points %d, num featurs %d\n", num_points, num_features);

                var dist_points: [0..num_points-1] BestPoint;  // Array de BestPoint

  // calculate the Euclidean distance between the Point to classify and each Point in the
  // training dataset (knowledge base)

  for i in 0..num_points-1 {
    var distance: real = 0.0;

    if DIST_METHOD == 1 {
    for j in 0..num_features-1 {
        var diff: real = new_point.features[j] - known_points[i].features[j];
        distance += diff * diff;
    }

  if DIST_METHOD == 1 {
   for j in 0..#num_features {
    const diff = new_point.features[j] - known_points[i].features[j];
    distance += diff * diff;
  }

  if USE_SQRT == 1 {
    if MATH_TYPE == 1 && DT == 2 {
      distance = sqrt(distance: real(32)); // float
    } else {
      distance = sqrt(distance); // double
    }
  }

} else if DIST_METHOD == 2 {
  for j in 0..#num_features {
    const diff = new_point.features[j] - known_points[i].features[j];
    const absdiff = if MATH_TYPE == 1 && DT == 2 then abs(diff: real(32)) else abs(diff);
    distance += absdiff;
  }
}

    dist_points[i].classification_id = known_points[i].classification_id;
    dist_points[i].distance = distance;
  }



  // Seleciona os k vizinhos mais próximos
select_k_nearest(dist_points, num_points, k);

// Copia os k primeiros para best_points
copy_k_nearest(dist_points, best_points, k);

// Em Chapel, normalmente não há necessidade de liberar memória, mas para simular:
if DIMEM != 0 {
  // Em Chapel, a coleta de lixo é automática. Nenhuma ação é necessária aqui.
  // Esta linha é apenas simbólica, como comentário:
  // free(dist_points); // Chapel não requer isso
}
    
}

}


/*
*	Classify using the k nearest neighbors identified by the get_k_NN
*	function. The classification uses plurality voting.
*
*	Note: it assumes that classes are identified from 0 to
*	num_classes - 1.
*/


// Corrigido: Acessando diretamente o BestPoint
proc plurality_voting(k: int, best_points: [] BestPoint, num_classes: int): CLASS_ID_TYPE {
  var histogram: [0..num_classes-1] uint;  // Array do histograma

  // Inicializa o histograma
  for i in 0..num_classes-1 {
    histogram[i] = 0;
  }

  // Construir o histograma com base nos k melhores pontos
  for i in 0..<k {
    var p = best_points[i];  // Acessando diretamente o BestPoint no array
    histogram[p.classification_id] += 1;
  }

  var classification_id: CLASS_ID_TYPE = best_points[0].classification_id;
  var max: CLASS_ID_TYPE = 1;

  // Encontrar a classe com a maior contagem
  for i in 0..num_classes-1 {
    if histogram[i] > max {
      max = histogram[i];
      classification_id = i:CLASS_ID_TYPE;
    }
  }

  return classification_id;
}

/*
* Classify a given Point (instance).
* It returns the classified class ID.
*/

proc knn_classifyinstance(new_point: Point, k: int, num_classes: int, known_points: [] Point, num_points: int, num_features: int): CLASS_ID_TYPE {
    // Array to hold the k nearest points
    var best_points: [0..k-1] BestPoint; // Array with the k nearest points to classify

    // Calculate the distances of the new point to each of the known points and get the k nearest points
    get_k_NN(new_point, known_points, num_points, best_points, k, num_features);

    // Use plurality voting to return the class inferred for the new point
    var classID = plurality_voting(k, best_points, num_classes);

    // Optionally print out the k best points (uncomment if needed)
    // for i in 0..k-1 {
    //     writeln("ID = ", best_points[i].classification_id, " | distance = ", best_points[i].distance);
    // }

    return classID;
}
