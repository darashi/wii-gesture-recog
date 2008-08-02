#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<ruby.h>
#include<math.h>

VALUE dtw(VALUE self, VALUE x, VALUE y){
  int n, m, d;
  int i,j,k;
  int t;
  double dij, f_min;

  n = FIX2INT(rb_funcall(x, rb_intern("size"),0));
  m = FIX2INT(rb_funcall(y, rb_intern("size"),0));
  d = FIX2INT(rb_funcall(rb_funcall(y, rb_intern("first"),0), rb_intern("size"), 0));
  double *f[n+1];
  for(i = 0; i <= n; i++){
    f[i] = calloc(sizeof(double),(m+1));
  }

  int *xx[n];
  int *yy[m];

  VALUE tmp_val;
  for(i = 0; i < n; i++){
    tmp_val = rb_funcall(x, rb_intern("fetch"),1,INT2FIX(i));
    xx[i] = malloc(sizeof(int)*(d));
    for(j = 0; j < d; j++){
      xx[i][j] =  FIX2INT(rb_funcall(tmp_val, rb_intern("fetch"),1,INT2FIX(j)));
    }
  }

  for(i = 0; i < m; i++){
    tmp_val = rb_funcall(y, rb_intern("fetch"),1,INT2FIX(i));
    yy[i] = malloc(sizeof(int)*(d));
    for(j = 0; j < d; j++){
      yy[i][j] =  FIX2INT(rb_funcall(tmp_val, rb_intern("fetch"),1,INT2FIX(j)));
    }
  }

  for(i = 1; i <= n; i++){
    for(j = 1; j <= m; j++){
      f_min = f[i][j-1];
      if(f[i-1][j] < f_min){f_min = f[i-1][j];}
      if(f[i-1][j-1] < f_min){f_min = f[i-1][j-1];}
      t = 0;
      for(k = 0; k < d; k++){
        t += (xx[i-1][k] - yy[j-1][k]) * (xx[i-1][k] - yy[j-1][k]);
      }
      dij = sqrt((double)t);
      f[i][j] = dij + f_min;
    }
  }

  for(i = 0; i < n; i++){
    free(xx[i]);
  }

  for(i = 0; i < m; i++){
    free(yy[i]);
  }

  return rb_float_new(f[n][m]);
}

VALUE Init_classifier_c(void)
{
  VALUE rb_cClassifierC;
  rb_cClassifierC = rb_define_class("ClassifierC", rb_cObject);
  rb_define_singleton_method(rb_cClassifierC, "dtw", dtw, 2);
  return Qnil;
}
