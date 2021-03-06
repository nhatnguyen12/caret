modelInfo <- list(label = "eXtreme Gradient Boosting",
                  library = c("xgboost"),
                  type = c("Regression", "Classification"),
                  parameters = data.frame(parameter = c('nrounds', 'lambda', 'alpha', 'eta'),
                                          class = rep("numeric", 4),
                                          label = c('# Boosting Iterations', 'L2 Regularization', 
                                                    'L1 Regularization', 'Learning Rate')),
                  grid = function(x, y, len = NULL, search = "grid")  {
                    if(search == "grid") {
                      out <- expand.grid(lambda = c(0, 10 ^ seq(-1, -4, length = len - 1)),
                                         alpha = c(0, 10 ^ seq(-1, -4, length = len - 1)),
                                         nrounds = floor((1:len) * 50),
                                         eta = 0.3)
                    } else {
                      out <- data.frame(lambda = 10^runif(len, min = -5, 0),
                                        alpha = 10^runif(len, min = -5, 0),
                                        nrounds = sample(1:100, size = len, replace = TRUE),
                                        eta = runif(len, max = 3))
                    }
                    out
                  },
                  loop = NULL,
                  fit = function(x, y, wts, param, lev, last, classProbs, ...) { 
                    if(class(x)[1] != "xgb.DMatrix") 
                      x <- as.matrix(x)
                    if(is.factor(y)) {
                      if(length(lev) == 2) {
                        y <- ifelse(y == lev[1], 1, 0) 
                        dat <- xgb.DMatrix(x, label = y)
                        out <- xgb.train(list(lambda = param$lambda, 
                                              alpha = param$alpha), 
                                         data = dat,
                                         nrounds = param$nrounds,
                                         objective = "binary:logistic",
                                         ...)
                      } else {
                        y <- as.numeric(y) - 1
                        dat <- xgb.DMatrix(x, label = y)
                        out <- xgb.train(list(lambda = param$lambda, 
                                              alpha = param$alpha), 
                                         data = dat,
                                         num_class = length(lev),
                                         nrounds = param$nrounds,
                                         objective = "multi:softprob",
                                         ...)
                      }     
                    } else {
                      dat <- xgb.DMatrix(as.matrix(x), label = y)
                      out <- xgb.train(list(lambda = param$lambda, 
                                            alpha = param$alpha), 
                                       data = dat,
                                       nrounds = param$nrounds,
                                       objective = "reg:linear",
                                       ...)
                    }
                    out
                  },
                  predict = function(modelFit, newdata, submodels = NULL) {
                    if(class(newdata)[1] != "xgb.DMatrix") 
                      newdata <- as.matrix(newdata)
                    out <- predict(modelFit, newdata)
                    if(modelFit$problemType == "Classification") {
                      if(length(modelFit$obsLevels) == 2) {
                        out <- ifelse(out >= .5, 
                                      modelFit$obsLevels[1], 
                                      modelFit$obsLevels[2])
                      } else {
                        out <- matrix(out, ncol = length(modelFit$obsLevels), byrow = TRUE)
                        out <- modelFit$obsLevels[apply(out, 1, which.max)]
                      }
                    }
                    out  
                  },
                  prob = function(modelFit, newdata, submodels = NULL) {
                    if(class(newdata)[1] != "xgb.DMatrix") 
                      newdata <- as.matrix(newdata)
                    out <- predict(modelFit, newdata)
                    if(length(modelFit$obsLevels) == 2) {
                      out <- cbind(out, 1 - out)
                      colnames(out) <- modelFit$obsLevels
                    } else {
                      out <- matrix(out, ncol = length(modelFit$obsLevels), byrow = TRUE)
                      colnames(out) <- modelFit$obsLevels
                    }
                    as.data.frame(out)
                  },
                  predictors = function(x, ...) {
                    imp <- xgb.importance(x$xNames, model = x)
                    x$xNames[x$xNames %in% imp$Feature]
                  },
                  varImp = function(object, numTrees = NULL, ...) {
                    imp <- xgb.importance(object$xNames, model = object)
                    imp <- as.data.frame(imp)[, 1:2]
                    rownames(imp) <- as.character(imp[,1])
                    imp <- imp[,2,drop = FALSE]
                    colnames(imp) <- "Overall"
                    imp   
                  },
                  levels = function(x) x$obsLevels,
                  tags = c("Linear Classifier Models", 
                           "Linear Regression Models",
                           "L1 Regularization Models",
                           "L2 Regularization Models",
                           "Boosting", "Ensemble Model", "Implicit Feature Selection"),
                  sort = function(x) {
                    # This is a toss-up, but the # trees probably adds
                    # complexity faster than number of splits
                    x[order(x$nrounds, x$alpha, x$lambda),] 
                  })
