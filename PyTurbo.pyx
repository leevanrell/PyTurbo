# distutils: language = c++

# Copyright 2019 Free Software Foundation, Inc.
#
# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.


from libcpp.vector cimport vector

cdef extern from "viterbi.cc":
    pass

cdef extern from "viterbi.h":
    cppclass viterbi:
        viterbi(int, int, int, vector[int], vector[int]) except +
        void viterbi_algorithm(int K, int S0, int, const float*, unsigned int*)
        int get_I()
        int get_S()
        int get_O()

cdef extern from "log_bcjr_base.cc":
    pass

cdef extern from "log_bcjr_base.h":
    cppclass log_bcjr_base:
        log_bcjr_base(int, int, int, vector[int], vector[int]) except +
        void log_bcjr_algorithm(vector[float], vector[float], vector[float], vector[float])
        int get_I()
        int get_S()
        int get_O()

cdef extern from "log_bcjr.h":
    cppclass log_bcjr(log_bcjr_base):
        log_bcjr(int, int, int, vector[int], vector[int]) except +
        @staticmethod
        float max_star(const float*, size_t)

cdef extern from "max_log_bcjr.h":
    cppclass max_log_bcjr(log_bcjr_base):
        max_log_bcjr(int, int, int, vector[int], vector[int]) except +
        @staticmethod
        float max(const float*, size_t)

import numpy

cdef class PyViterbi:
    cdef int I, S, O
    cdef viterbi* cpp_viterbi

    def __cinit__(self, int I, int S, int O, vector[int] NS, vector[int] OS):
        self.cpp_viterbi = new viterbi(I, S, O, NS, OS)
        self.I = self.cpp_viterbi.get_I()
        self.S = self.cpp_viterbi.get_S()
        self.O = self.cpp_viterbi.get_O()

    def __dealloc__(self):
        del self.cpp_viterbi

    def viterbi_algorithm(self, S0, SK, float[::1] _in):
        cdef int K = _in.shape[0]/self.O
        cdef unsigned int[::1] _out = numpy.zeros(K, dtype=numpy.uint32)

        self.cpp_viterbi.viterbi_algorithm(K, S0, SK, &_in[0], &_out[0])

        return numpy.asarray(_out, dtype=numpy.uint16)

cdef class PyLogBCJR:
    cdef int I, S, O
    cdef log_bcjr* cpp_log_bcjr

    def __cinit__(self, int I, int S, int O, vector[int] NS, vector[int] OS):
        self.cpp_log_bcjr= new log_bcjr(I, S, O, NS, OS)
        self.I = self.cpp_log_bcjr.get_I()
        self.S = self.cpp_log_bcjr.get_S()
        self.O = self.cpp_log_bcjr.get_O()

    def __dealloc__(self):
        del self.cpp_log_bcjr

    @staticmethod
    def max_star(float[::1] vec):
        cdef size_t n_ele = vec.shape[0]

        return log_bcjr.max_star(&vec[0], n_ele)

    def log_bcjr_algorithm(self, vector[float] &A0, vector[float] &BK, vector[float] &_in):
        cdef vector[float] _out

        self.cpp_log_bcjr.log_bcjr_algorithm(A0, BK, _in, _out)

        return numpy.asarray(_out, dtype=numpy.float32)

cdef class PyMaxLogBCJR:
    cdef int I, S, O
    cdef max_log_bcjr* cpp_max_log_bcjr

    def __cinit__(self, int I, int S, int O, vector[int] NS, vector[int] OS):
        self.cpp_max_log_bcjr= new max_log_bcjr(I, S, O, NS, OS)
        self.I = self.cpp_max_log_bcjr.get_I()
        self.S = self.cpp_max_log_bcjr.get_S()
        self.O = self.cpp_max_log_bcjr.get_O()

    def __dealloc__(self):
        del self.cpp_max_log_bcjr

    @staticmethod
    def max(float[::1] vec):
        cdef size_t n_ele = vec.shape[0]

        return max_log_bcjr.max(&vec[0], n_ele)

    def log_bcjr_algorithm(self, vector[float] &A0, vector[float] &BK, vector[float] &_in):
        cdef vector[float] _out

        self.cpp_max_log_bcjr.log_bcjr_algorithm(A0, BK, _in, _out)

        return numpy.asarray(_out, dtype=numpy.float32)
