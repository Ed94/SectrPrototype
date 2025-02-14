// This file was generated automatially by gencpp's singleheader.cpp(See: https://github.com/Ed94/gencpp)

#pragma once

#ifdef __clang__
#	pragma clang diagnostic push
#	pragma clang diagnostic ignored "-Wunused-const-variable"
#	pragma clang diagnostic ignored "-Wunused-but-set-variable"
#	pragma clang diagnostic ignored "-Wswitch"
#	pragma clang diagnostic ignored "-Wunused-variable"
#   pragma clang diagnostic ignored "-Wunknown-pragmas"
#	pragma clang diagnostic ignored "-Wvarargs"
#	pragma clang diagnostic ignored "-Wunused-function"
#	pragma clang diagnostic ignored "-Wbraced-scalar-init"
#   pragma clang diagnostic ignored "-W#pragma-messages"
#	pragma clang diagnostic ignored "-Wstatic-in-inline"
#endif

#ifdef __GNUC__
#	pragma GCC diagnostic push
#   pragma GCC diagnostic ignored "-Wunknown-pragmas"
#	pragma GCC diagnostic ignored "-Wcomment"
#	pragma GCC diagnostic ignored "-Wswitch"
#	pragma GCC diagnostic ignored "-Wunused-variable"
#endif
/*
	gencpp: An attempt at "simple" staged metaprogramming for c/c++.

	See Readme.md for more information from the project repository.

	Define GEN_IMPLEMENTATION before including this file in a single compilation unit.

	Public Address:
	https://github.com/Ed94/gencpp  --------------------------------------------------------------.
	|   _____                               _____ _                       _                        |
	|  / ____)                             / ____} |                     | |                       |
	| | / ___  ___ _ __   ___ _ __  _ __  | {___ | |__ _ _, __ _, ___  __| |                       |
	| | |{_  |/ _ \ '_ \ / __} '_ l| '_ l `\___ \| __/ _` |/ _` |/ _ \/ _` |                       |
	| | l__j | ___/ | | | {__; |+l } |+l | ____) | l| (_| | {_| | ___/ (_| |                       |
	|  \_____|\___}_l |_|\___} ,__/| ,__/ (_____/ \__\__/_|\__, |\___}\__,_l                       |
	|     Singleheader       | |   | |                      __} |                                  |
	|                        l_l   l_l                     {___/                                   |
	! ----------------------------------------------------------------------- VERSION: v0.25-Alpha |
	! ============================================================================================ |
	! WARNING: THIS IS AN ALPHA VERSION OF THE LIBRARY, USE AT YOUR OWN DISCRETION                 |
	! NEVER DO CODE GENERATION WITHOUT AT LEAST HAVING CONTENT IN A CODEBASE UNDER VERSION CONTROL |
	! ============================================================================================ /
*/
#if ! defined(GEN_DONT_ENFORCE_GEN_TIME_GUARD) && ! defined(GEN_TIME)
#	error Gen.hpp : GEN_TIME not defined
#endif

//! If its desired to roll your own dependencies, define GEN_ROLL_OWN_DEPENDENCIES before including this file.
// Dependencies are derived from the c-zpl library: https://github.com/zpl-c/zpl
#ifndef GEN_ROLL_OWN_DEPENDENCIES

#pragma region Platform Detection

/* Platform architecture */

#if defined( _WIN64 ) || defined( __x86_64__ ) || defined( _M_X64 ) || defined( __64BIT__ ) || defined( __powerpc64__ ) || defined( __ppc64__ ) || defined( __aarch64__ )
#	ifndef GEN_ARCH_64_BIT
#		define GEN_ARCH_64_BIT 1
#	endif
#else
#	ifndef GEN_ARCH_32_BItxt_StrCaT
#		define GEN_ARCH_32_BIT 1
#	endif
#endif

/* Platform OS */

#if defined( _WIN32 ) || defined( _WIN64 )
#	ifndef GEN_SYSTEM_WINDOWS
#		define GEN_SYSTEM_WINDOWS 1
#	endif
#elif defined( __APPLE__ ) && defined( __MACH__ )
#	ifndef GEN_SYSTEM_OSX
#		define GEN_SYSTEM_OSX 1
#	endif
#	ifndef GEN_SYSTEM_MACOS
#		define GEN_SYSTEM_MACOS 1
#	endif
#elif defined( __unix__ )
#	ifndef GEN_SYSTEM_UNIX
#		define GEN_SYSTEM_UNIX 1
#	endif
#	if defined( ANDROID ) || defined( __ANDROID__ )
#		ifndef GEN_SYSTEM_ANDROID
#			define GEN_SYSTEM_ANDROID 1
#		endif
#		ifndef GEN_SYSTEM_LINUX
#			define GEN_SYSTEM_LINUX 1
#		endif
#	elif defined( __linux__ )
#		ifndef GEN_SYSTEM_LINUX
#			define GEN_SYSTEM_LINUX 1
#		endif
#	elif defined( __FreeBSD__ ) || defined( __FreeBSD_kernel__ )
#		ifndef GEN_SYSTEM_FREEBSD
#			define GEN_SYSTEM_FREEBSD 1
#		endif
#	elif defined( __OpenBSD__ )
#		ifndef GEN_SYSTEM_OPENBSD
#			define GEN_SYSTEM_OPENBSD 1
#		endif
#	elif defined( __EMSCRIPTEN__ )
#		ifndef GEN_SYSTEM_EMSCRIPTEN
#			define GEN_SYSTEM_EMSCRIPTEN 1
#		endif
#	elif defined( __CYGWIN__ )
#		ifndef GEN_SYSTEM_CYGWIN
#			define GEN_SYSTEM_CYGWIN 1
#		endif
#	else
#		error This UNIX operating system is not supported
#	endif
#else
#	error This operating system is not supported
#endif

/* Platform compiler */

#if defined( _MSC_VER )
#	pragma message("Detected MSVC")
// #	define GEN_COMPILER_CLANG 0
#	define GEN_COMPILER_MSVC  1
// #	define GEN_COMPILER_GCC   0
#elif defined( __GNUC__ )
#	pragma message("Detected GCC")
// #	define GEN_COMPILER_CLANG 0
// #	define GEN_COMPILER_MSVC  0
#	define GEN_COMPILER_GCC   1
#elif defined( __clang__ )
#	pragma message("Detected CLANG")
#	define GEN_COMPILER_CLANG 1
// #	define GEN_COMPILER_MSVC  0
// #	define GEN_COMPILER_GCC   0
#else
#	error Unknown compiler
#endif

#if defined( __has_attribute )
#	define GEN_HAS_ATTRIBUTE( attribute ) __has_attribute( attribute )
#else
#	define GEN_HAS_ATTRIBUTE( attribute ) ( 0 )
#endif

#if defined(GEN_GCC_VERSION_CHECK)
#  undef GEN_GCC_VERSION_CHECK
#endif
#if defined(GEN_GCC_VERSION)
#  define GEN_GCC_VERSION_CHECK(major,minor,patch) (GEN_GCC_VERSION >= GEN_VERSION_ENCODE(major, minor, patch))
#else
#  define GEN_GCC_VERSION_CHECK(major,minor,patch) (0)
#endif

#if !defined(GEN_COMPILER_C)
#	ifdef __cplusplus
#		define GEN_COMPILER_C   0
#		define GEN_COMPILER_CPP 1
#	else
#		if defined(__STDC__)
#			define GEN_COMPILER_C   1
#		    define GEN_COMPILER_CPP 0
#		else
            // Fallback for very old C compilers
#			define GEN_COMPILER_C   1
#		    define GEN_COMPILER_CPP 0
#		endif
#   endif
#endif

#if GEN_COMPILER_C
#pragma message("GENCPP: Detected C")
#endif

#pragma endregion Platform Detection

#pragma region Mandatory Includes

#	include <stdarg.h>
#	include <stddef.h>

#	if defined( GEN_SYSTEM_WINDOWS )
#		include <intrin.h>
#	endif

#if GEN_COMPILER_C
#include <assert.h>
#include <stdbool.h>
#endif

#pragma endregion Mandatory Includes

#if GEN_DONT_USE_NAMESPACE || GEN_COMPILER_C
#	if GEN_COMPILER_C
#		define GEN_NS
#		define GEN_NS_BEGIN
#		define GEN_NS_END
#	else
#		define GEN_NS              ::
#		define GEN_NS_BEGIN
#		define GEN_NS_END
#	endif
#else
#	define GEN_NS              gen::
#	define GEN_NS_BEGIN        namespace gen {
#	define GEN_NS_END          }
#endif

GEN_NS_BEGIN

#pragma region Macros

#ifndef GEN_API
#if GEN_COMPILER_MSVC
    #ifdef GEN_DYN_LINK
        #ifdef GEN_DYN_EXPORT
            #define GEN_API __declspec(dllexport)
        #else
            #define GEN_API __declspec(dllimport)
        #endif
    #else
        #define GEN_API  // Empty for static builds
    #endif
#else
    #ifdef GEN_DYN_LINK
        #define GEN_API __attribute__((visibility("default")))
    #else
        #define GEN_API  // Empty for static builds
    #endif
#endif
#endif // GEN_API

#ifndef global // Global variables
#	if defined(GEN_STATIC_LINK) || defined(GEN_DYN_LINK)
#		define global         
#	else
#		define global static
#	endif
#endif
#ifndef internal
#define internal      static    // Internal linkage
#endif
#ifndef local_persist
#define local_persist static    // Local Persisting variables
#endif

#ifndef bit
#define bit( Value )                         ( 1 << Value )
#endif

#ifndef bitfield_is_set
#define bitfield_is_set( Type, Field, Mask ) ( (scast(Type, Mask) & scast(Type, Field)) == scast(Type, Mask) )
#endif

// Mainly intended for forcing the base library to utilize only C-valid constructs or type coercion
#ifndef GEN_C_LIKE_CPP
#define GEN_C_LIKE_CPP 0
#endif

#if GEN_COMPILER_CPP
#	ifndef cast
#	define cast( type, value ) (tmpl_cast<type>( value ))
#	endif
#else
#	ifndef cast
#	define cast( type, value )  ( (type)(value) )
#	endif
#endif

#if GEN_COMPILER_CPP
#	ifndef ccast
#	define ccast( type, value ) ( const_cast< type >( (value) ) )
#	endif
#	ifndef pcast
#	define pcast( type, value ) ( * reinterpret_cast< type* >( & ( value ) ) )
#	endif
#	ifndef rcast
#	define rcast( type, value ) reinterpret_cast< type >( value )
#	endif
#	ifndef scast
#	define scast( type, value ) static_cast< type >( value )
#	endif
#else
#	ifndef ccast
#	define ccast( type, value ) ( (type)(value) )
#	endif
#	ifndef pcast
#	define pcast( type, value ) ( * (type*)(& value) )
#	endif
#	ifndef rcast
#	define rcast( type, value ) ( (type)(value) )
#	endif
#	ifndef scast
#	define scast( type, value ) ( (type)(value) )
#	endif
#endif

#ifndef stringize
#define stringize_va( ... ) #__VA_ARGS__
#define stringize( ... )    stringize_va( __VA_ARGS__ )
#endif

#define src_line_str stringize(__LINE__)

#ifndef do_once
#define do_once()                                                                            \
	local_persist int __do_once_counter_##src_line_str  = 0;                                 \
    for(;      __do_once_counter_##src_line_str != 1; __do_once_counter_##src_line_str = 1 ) \

#define do_once_defer( expression )                                                                 \
    local_persist int __do_once_counter_##src_line_str  = 0;                                        \
    for(;__do_once_counter_##src_line_str != 1; __do_once_counter_##src_line_str = 1, (expression)) \

#define do_once_start      \
	do                     \
	{                      \
		local_persist      \
		bool done = false; \
		if ( done )        \
			break;         \
		done = true;

#define do_once_end        \
	}                      \
	while(0);
#endif

#ifndef labeled_scope_start
#define labeled_scope_start if ( false ) {
#define labeled_scope_end   }
#endif

#ifndef         compiler_decorated_func_name
#   ifdef COMPILER_CLANG
#       define  compiler_decorated_func_name __PRETTY_NAME__
#   elif defined(COMPILER_MSVC)
#   	define compiler_decorated_func_name __FUNCDNAME__
#   endif
#endif

#ifndef num_args_impl

// This is essentially an arg couneter version of GEN_SELECT_ARG macros
// See section : _Generic function overloading for that usage (explains this heavier case)

#define num_args_impl( _0,                                 \
		_1,  _2,  _3,  _4,  _5,  _6,  _7,  _8,  _9, _10,   \
		_11, _12, _13, _14, _15, _16, _17, _18, _19, _20,  \
		_21, _22, _23, _24, _25, _26, _27, _28, _29, _30,  \
		_31, _32, _33, _34, _35, _36, _37, _38, _39, _40,  \
		_41, _42, _43, _44, _45, _46, _47, _48, _49, _50,  \
		_51, _52, _53, _54, _55, _56, _57, _58, _59, _60,  \
		_61, _62, _63, _64, _65, _66, _67, _68, _69, _70,  \
		_71, _72, _73, _74, _75, _76, _77, _78, _79, _80,  \
		_81, _82, _83, _84, _85, _86, _87, _88, _89, _90,  \
		_91, _92, _93, _94, _95, _96, _97, _98, _99, _100, \
		N, ...                                             \
	) N

// ## deletes preceding comma if _VA_ARGS__ is empty (GCC, Clang)
#define num_args(...)                            \
	num_args_impl(_, ## __VA_ARGS__,             \
		100, 99, 98, 97, 96, 95, 94, 93, 92, 91, \
		 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, \
		 80, 79, 78, 77, 76, 75, 74, 73, 72, 71, \
		 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, \
		 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, \
		 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, \
		 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, \
		 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, \
		 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, \
		 10,  9,  8,  7,  6,  5,  4,  3,  2,  1, \
		 0                                       \
	)
#endif

#ifndef clamp
#define clamp( x, lower, upper )      min( max( ( x ), ( lower ) ), ( upper ) )
#endif
#ifndef count_of
#define count_of( x )                 ( ( size_of( x ) / size_of( 0 [ x ] ) ) / ( ( ssize )( ! ( size_of( x ) % size_of( 0 [ x ] ) ) ) ) )
#endif
#ifndef is_between
#define is_between( x, lower, upper ) ( ( ( lower ) <= ( x ) ) && ( ( x ) <= ( upper ) ) )
#endif
#ifndef size_of
#define size_of( x )                  ( ssize )( sizeof( x ) )
#endif

#ifndef max
#define max( a, b ) ( (a > b) ? (a) : (b) )
#endif
#ifndef min
#define min( a, b ) ( (a < b) ? (a) : (b) )
#endif

#if GEN_COMPILER_MSVC || GEN_COMPILER_TINYC
#	define offset_of( Type, element ) ( ( GEN_NS( ssize ) ) & ( ( ( Type* )0 )->element ) )
#else
#	define offset_of( Type, element ) __builtin_offsetof( Type, element )
#endif

#ifndef        forceinline
#	if GEN_COMPILER_MSVC
#		define forceinline __forceinline
#	elif GEN_COMPILER_GCC
#		define forceinline inline __attribute__((__always_inline__))
#	elif GEN_COMPILER_CLANG
#	if __has_attribute(__always_inline__)
#		define forceinline inline __attribute__((__always_inline__))
#	else
#		define forceinline
#	endif
#	else
#		define forceinline
#	endif
#endif

#ifndef        neverinline
#	if GEN_COMPILER_MSVC
#		define neverinline __declspec( noinline )
#	elif GEN_COMPILER_GCC
#		define neverinline __attribute__( ( __noinline__ ) )
#	elif GEN_COMPILER_CLANG
#	if __has_attribute(__always_inline__)
#		define neverinline __attribute__( ( __noinline__ ) )
#	else
#		define neverinline
#	endif
#	else
#		define neverinline
#	endif
#endif

#if GEN_COMPILER_C
#ifndef static_assert
#undef  static_assert
    #if GEN_COMPILER_C && __STDC_VERSION__ >= 201112L
        #define static_assert(condition, message) _Static_assert(condition, message)
    #else
        #define static_assert(condition, message) typedef char static_assertion_##__LINE__[(condition)?1:-1]
	#endif
#endif
#endif

#if GEN_COMPILER_CPP
// Already Defined
#elif GEN_COMPILER_C && __STDC_VERSION__ >= 201112L
#	define thread_local _Thread_local
#elif GEN_COMPILER_MSVC
#	define thread_local __declspec(thread)
#elif GEN_COMPILER_CLANG
#	define thread_local __thread
#else
#	error "No thread local support"
#endif

#if ! defined(typeof) && (!GEN_COMPILER_C || __STDC_VERSION__ < 202311L)
#	if ! GEN_COMPILER_C
#		define typeof decltype
#	elif defined(_MSC_VER)
#		define typeof __typeof__
#	elif defined(__GNUC__) || defined(__clang__)
#		define typeof __typeof__
#	else
#		error "Compiler not supported"
#	endif
#endif

#ifndef GEN_API_C_BEGIN
#	if GEN_COMPILER_C
#		define GEN_API_C_BEGIN
#		define GEN_API_C_END
#	else
#		define GEN_API_C_BEGIN extern "C" {
#		define GEN_API_C_END   }
#	endif
#endif

#if GEN_COMPILER_C
#	if __STDC_VERSION__ >= 202311L
#		define enum_underlying(type) : type
#	else
#		define enum_underlying(type)
#   endif
#else
#	define enum_underlying(type) : type
#endif

#if GEN_COMPILER_C
#	ifndef nullptr
#		define nullptr NULL
#	endif

#	ifndef GEN_REMOVE_PTR
#		define GEN_REMOVE_PTR(type) typeof(* ( (type) NULL) )
#	endif
#endif

#if ! defined(GEN_PARAM_DEFAULT) && GEN_COMPILER_CPP
#	define GEN_PARAM_DEFAULT = {}
#else
#	define GEN_PARAM_DEFAULT
#endif

#if GEN_COMPILER_CPP
    #define struct_init(type, value) {value}
#else
    #define struct_init(type, value) {value}
#endif

#if 0
#ifndef GEN_OPTIMIZE_MAPPINGS_BEGIN
#	define GEN_OPTIMIZE_MAPPINGS_BEGIN _pragma(optimize("gt", on))
#	define GEN_OPITMIZE_MAPPINGS_END   _pragma(optimize("", on))
#endif
#else
#	define GEN_OPTIMIZE_MAPPINGS_BEGIN
#	define GEN_OPITMIZE_MAPPINGS_END
#endif

#ifndef get_optional
#	if GEN_COMPILER_C
#		define get_optional(opt) opt ? *opt : (typeof(*opt)){0}
#	else
#		define get_optional(opt) opt
#	endif
#endif

#pragma endregion Macros

#pragma region Basic Types

#define GEN_U8_MIN 0u
#define GEN_U8_MAX 0xffu
#define GEN_I8_MIN ( -0x7f - 1 )
#define GEN_I8_MAX 0x7f

#define GEN_U16_MIN 0u
#define GEN_U16_MAX 0xffffu
#define GEN_I16_MIN ( -0x7fff - 1 )
#define GEN_I16_MAX 0x7fff

#define GEN_U32_MIN 0u
#define GEN_U32_MAX 0xffffffffu
#define GEN_I32_MIN ( -0x7fffffff - 1 )
#define GEN_I32_MAX 0x7fffffff

#define GEN_U64_MIN 0ull
#define GEN_U64_MAX 0xffffffffffffffffull
#define GEN_I64_MIN ( -0x7fffffffffffffffll - 1 )
#define GEN_I64_MAX 0x7fffffffffffffffll

#if defined( GEN_ARCH_32_BIT )
#	define GEN_USIZE_MIN GEN_U32_MIN
#	define GEN_USIZE_MAX GEN_U32_MAX
#	define GEN_ISIZE_MIN GEN_S32_MIN
#	define GEN_ISIZE_MAX GEN_S32_MAX
#elif defined( GEN_ARCH_64_BIT )
#	define GEN_USIZE_MIN GEN_U64_MIN
#	define GEN_USIZE_MAX GEN_U64_MAX
#	define GEN_ISIZE_MIN GEN_I64_MIN
#	define GEN_ISIZE_MAX GEN_I64_MAX
#else
#	error Unknown architecture size. This library only supports 32 bit and 64 bit architectures.
#endif

#define GEN_F32_MIN 1.17549435e-38f
#define GEN_F32_MAX 3.40282347e+38f
#define GEN_F64_MIN 2.2250738585072014e-308
#define GEN_F64_MAX 1.7976931348623157e+308

#if defined( GEN_COMPILER_MSVC )
#	if _MSC_VER < 1300
typedef unsigned char  u8;
typedef signed   char  s8;
typedef unsigned short u16;
typedef signed   short s16;
typedef unsigned int   u32;
typedef signed   int   s32;
#    else
typedef unsigned __int8  u8;
typedef signed   __int8  s8;
typedef unsigned __int16 u16;
typedef signed   __int16 s16;
typedef unsigned __int32 u32;
typedef signed   __int32 s32;
#    endif
typedef unsigned __int64 u64;
typedef signed   __int64 s64;
#else
#	include <stdint.h>

typedef uint8_t  u8;
typedef int8_t   s8;
typedef uint16_t u16;
typedef int16_t  s16;
typedef uint32_t u32;
typedef int32_t  s32;
typedef uint64_t u64;
typedef int64_t  s64;
#endif

static_assert( sizeof( u8 )  == sizeof( s8 ),  "sizeof(u8) != sizeof(s8)" );
static_assert( sizeof( u16 ) == sizeof( s16 ), "sizeof(u16) != sizeof(s16)" );
static_assert( sizeof( u32 ) == sizeof( s32 ), "sizeof(u32) != sizeof(s32)" );
static_assert( sizeof( u64 ) == sizeof( s64 ), "sizeof(u64) != sizeof(s64)" );

static_assert( sizeof( u8 )  == 1, "sizeof(u8) != 1" );
static_assert( sizeof( u16 ) == 2, "sizeof(u16) != 2" );
static_assert( sizeof( u32 ) == 4, "sizeof(u32) != 4" );
static_assert( sizeof( u64 ) == 8, "sizeof(u64) != 8" );

typedef size_t    usize;
typedef ptrdiff_t ssize;

static_assert( sizeof( usize ) == sizeof( ssize ), "sizeof(usize) != sizeof(ssize)" );

// NOTE: (u)zpl_intptr is only here for semantic reasons really as this library will only support 32/64 bit OSes.
#if defined( _WIN64 )
typedef signed __int64   sptr;
typedef unsigned __int64 uptr;
#elif defined( _WIN32 )
// NOTE; To mark types changing their size, e.g. zpl_intptr
#	ifndef _W64
#		if ! defined( __midl ) && ( defined( _X86_ ) || defined( _M_IX86 ) ) && _MSC_VER >= 1300
#			define _W64 __w64
#		else
#			define _W64
#		endif
#	endif
typedef _W64 signed int   sptr;
typedef _W64 unsigned int uptr;
#else
typedef uintptr_t uptr;
typedef intptr_t  sptr;
#endif

static_assert( sizeof( uptr ) == sizeof( sptr ), "sizeof(uptr) != sizeof(sptr)" );

typedef float  f32;
typedef double f64;

static_assert( sizeof( f32 ) == 4, "sizeof(f32) != 4" );
static_assert( sizeof( f64 ) == 8, "sizeof(f64) != 8" );

typedef s8  b8;
typedef s16 b16;
typedef s32 b32;

typedef void*       mem_ptr;
typedef void const* mem_ptr_const ;

#if GEN_COMPILER_CPP
template<typename Type> uptr to_uptr( Type* ptr ) { return (uptr)ptr; }
template<typename Type> sptr to_sptr( Type* ptr ) { return (sptr)ptr; }

template<typename Type> mem_ptr       to_mem_ptr      ( Type ptr ) { return (mem_ptr)      ptr; }
template<typename Type> mem_ptr_const to_mem_ptr_const( Type ptr ) { return (mem_ptr_const)ptr; }
#else
#define to_uptr( ptr ) ((uptr)(ptr))
#define to_sptr( ptr ) ((sptr)(ptr))

#define to_mem_ptr( ptr)       ((mem_ptr)ptr)
#define to_mem_ptr_const( ptr) ((mem_ptr)ptr)
#endif

#pragma endregion Basic Types

#pragma region Debug

#if GEN_BUILD_DEBUG
#	if defined( GEN_COMPILER_MSVC )
#		if _MSC_VER < 1300
// #pragma message("GEN_BUILD_DEBUG: __asm int 3")
#			define GEN_DEBUG_TRAP() __asm int 3 /* Trap to debugger! */
#		else
// #pragma message("GEN_BUILD_DEBUG: __debugbreak()")
#			define GEN_DEBUG_TRAP() __debugbreak()
#		endif
#	elif defined( GEN_COMPILER_TINYC )
#		define GEN_DEBUG_TRAP() process_exit( 1 )
#	else
#		define GEN_DEBUG_TRAP() __builtin_trap()
#	endif
#else
// #pragma message("GEN_BUILD_DEBUG: omitted")
#	define GEN_DEBUG_TRAP()
#endif

#define GEN_ASSERT( cond ) GEN_ASSERT_MSG( cond, NULL )

#define GEN_ASSERT_MSG( cond, msg, ... )                                                              \
	do                                                                                                \
	{                                                                                                 \
		if ( ! ( cond ) )                                                                             \
		{                                                                                             \
			assert_handler( #cond, __FILE__, __func__, scast( s64, __LINE__ ), msg, ##__VA_ARGS__ );  \
			GEN_DEBUG_TRAP();                                                                         \
		}                                                                                             \
	} while ( 0 )

#define GEN_ASSERT_NOT_NULL( ptr ) GEN_ASSERT_MSG( ( ptr ) != NULL, #ptr " must not be NULL" )

// NOTE: Things that shouldn't happen with a message!
#define GEN_PANIC( msg, ... ) GEN_ASSERT_MSG( 0, msg, ##__VA_ARGS__ )

#if GEN_BUILD_DEBUG
	#define GEN_FATAL( ... )                               \
	do                                                     \
	{                                                      \
		local_persist thread_local                         \
		char buf[GEN_PRINTF_MAXLEN] = { 0 };               \
		                                                   \
		c_str_fmt(buf, GEN_PRINTF_MAXLEN, __VA_ARGS__);    \
		GEN_PANIC(buf);                                    \
	}                                                      \
	while (0)
#else

#	define GEN_FATAL( ... )                  \
	do                                       \
	{                                        \
		c_str_fmt_out_err( __VA_ARGS__ );    \
		GEN_DEBUG_TRAP();                    \
		process_exit(1);                     \
	}                                        \
	while (0)
#endif

GEN_API void assert_handler( char const* condition, char const* file, char const* function, s32 line, char const* msg, ... );
GEN_API s32  assert_crash( char const* condition );
GEN_API void process_exit( u32 code );

#pragma endregion Debug

#pragma region Memory

#define kilobytes( x ) (          ( x ) * ( s64 )( 1024 ) )
#define megabytes( x ) ( kilobytes( x ) * ( s64 )( 1024 ) )
#define gigabytes( x ) ( megabytes( x ) * ( s64 )( 1024 ) )
#define terabytes( x ) ( gigabytes( x ) * ( s64 )( 1024 ) )

#define GEN__ONES          ( scast( GEN_NS usize, - 1) / GEN_U8_MAX )
#define GEN__HIGHS         ( GEN__ONES * ( GEN_U8_MAX / 2 + 1 ) )
#define GEN__HAS_ZERO( x ) ( ( ( x ) - GEN__ONES ) & ~( x ) & GEN__HIGHS )

template< class Type >
void swap( Type& a, Type& b )
{
	Type tmp = a;
	a = b;
	b = tmp;
}

//! Checks if value is power of 2.
b32 is_power_of_two( ssize x );

//! Aligns address to specified alignment.
void* align_forward( void* ptr, ssize alignment );

//! Aligns value to a specified alignment.
s64 align_forward_by_value( s64 value, ssize alignment );

//! Moves pointer forward by bytes.
void* pointer_add( void* ptr, ssize bytes );

//! Moves pointer forward by bytes.
void const* pointer_add_const( void const* ptr, ssize bytes );

//! Calculates difference between two addresses.
ssize pointer_diff( void const* begin, void const* end );

//! Copy non-overlapping memory from source to destination.
GEN_API void* mem_copy( void* dest, void const* source, ssize size );

//! Search for a constant value within the size limit at memory location.
GEN_API void const* mem_find( void const* data, u8 byte_value, ssize size );

//! Copy memory from source to destination.
void* mem_move( void* dest, void const* source, ssize size );

//! Set constant value at memory location with specified size.
void* mem_set( void* data, u8 byte_value, ssize size );

//! @param ptr Memory location to clear up.
//! @param size The size to clear up with.
void zero_size( void* ptr, ssize size );

//! Clears up an item.
#define zero_item( t ) zero_size( ( t ), size_of( *( t ) ) )    // NOTE: Pass pointer of struct

//! Clears up an array.
#define zero_array( a, count ) zero_size( ( a ), size_of( *( a ) ) * count )

enum AllocType : u8
{
	EAllocation_ALLOC,
	EAllocation_FREE,
	EAllocation_FREE_ALL,
	EAllocation_RESIZE,
};

typedef void*(AllocatorProc)( void* allocator_data, AllocType type, ssize size, ssize alignment, void* old_memory, ssize old_size, u64 flags );

struct AllocatorInfo
{
	AllocatorProc* Proc;
	void*          Data;
};

enum AllocFlag
{
	ALLOCATOR_FLAG_CLEAR_TO_ZERO = bit( 0 ),
};

#ifndef GEN_DEFAULT_MEMORY_ALIGNMENT
#	define GEN_DEFAULT_MEMORY_ALIGNMENT ( 2 * size_of( void* ) )
#endif

#ifndef GEN_DEFAULT_ALLOCATOR_FLAGS
#	define GEN_DEFAULT_ALLOCATOR_FLAGS ( ALLOCATOR_FLAG_CLEAR_TO_ZERO )
#endif

//! Allocate memory with default alignment.
void* alloc( AllocatorInfo a, ssize size );

//! Allocate memory with specified alignment.
void* alloc_align( AllocatorInfo a, ssize size, ssize alignment );

//! Free allocated memory.
void allocator_free( AllocatorInfo a, void* ptr );

//! Free all memory allocated by an allocator.
void free_all( AllocatorInfo a );

//! Resize an allocated memory.
void* resize( AllocatorInfo a, void* ptr, ssize old_size, ssize new_size );

//! Resize an allocated memory with specified alignment.
void* resize_align( AllocatorInfo a, void* ptr, ssize old_size, ssize new_size, ssize alignment );

//! Allocate memory for an item.
#define alloc_item( allocator_, Type ) ( Type* )alloc( allocator_, size_of( Type ) )

//! Allocate memory for an array of items.
#define alloc_array( allocator_, Type, count ) ( Type* )alloc( allocator_, size_of( Type ) * ( count ) )

/* heap memory analysis tools */
/* define GEN_HEAP_ANALYSIS to enable this feature */
/* call zpl_heap_stats_init at the beginning of the entry point */
/* you can call zpl_heap_stats_check near the end of the execution to validate any possible leaks */
GEN_API void  heap_stats_init( void );
GEN_API ssize heap_stats_used_memory( void );
GEN_API ssize heap_stats_alloc_count( void );
GEN_API void  heap_stats_check( void );

//! Allocate/Resize memory using default options.

//! Use this if you don't need a "fancy" resize allocation
void* default_resize_align( AllocatorInfo a, void* ptr, ssize old_size, ssize new_size, ssize alignment );

GEN_API void* heap_allocator_proc( void* allocator_data, AllocType type, ssize size, ssize alignment, void* old_memory, ssize old_size, u64 flags );

//! The heap allocator backed by operating system's memory manager.
constexpr AllocatorInfo heap( void ) { AllocatorInfo allocator = { heap_allocator_proc, nullptr }; return allocator; }

//! Helper to allocate memory using heap allocator.
#define malloc( sz ) alloc( heap(), sz )

//! Helper to free memory allocated by heap allocator.
#define mfree( ptr ) allocator_free( heap(), ptr )

struct VirtualMemory
{
	void*  data;
	ssize size;
};

//! Initialize virtual memory from existing data.
GEN_API VirtualMemory vm_from_memory( void* data, ssize size );

//! Allocate virtual memory at address with size.

//! @param addr The starting address of the region to reserve. If NULL, it lets operating system to decide where to allocate it.
//! @param size The size to serve.
GEN_API VirtualMemory vm_alloc( void* addr, ssize size );

//! Release the virtual memory.
GEN_API b32 vm_free( VirtualMemory vm );

//! Trim virtual memory.
GEN_API VirtualMemory vm_trim( VirtualMemory vm, ssize lead_size, ssize size );

//! Purge virtual memory.
GEN_API b32 vm_purge( VirtualMemory vm );

//! Retrieve VM's page size and alignment.
GEN_API ssize virtual_memory_page_size( ssize* alignment_out );

#pragma region Arena
struct Arena;

AllocatorInfo arena_allocator_info( Arena* arena );

// Remove static keyword and rename allocator_proc
GEN_API void* arena_allocator_proc(void* allocator_data, AllocType type, ssize size, ssize alignment, void* old_memory, ssize old_size, u64 flags);

// Add these declarations after the Arena struct
Arena arena_init_from_allocator(AllocatorInfo backing, ssize size);
Arena arena_init_from_memory   ( void* start, ssize size );

Arena arena_init_sub      (Arena* parent, ssize size);
ssize arena_alignment_of  (Arena* arena, ssize alignment);
void  arena_check         (Arena* arena);
void  arena_free          (Arena* arena);
ssize arena_size_remaining(Arena* arena, ssize alignment);

struct Arena
{
	AllocatorInfo Backing;
	void*         PhysicalStart;
	ssize         TotalSize;
	ssize         TotalUsed;
	ssize         TempCount;

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
#pragma region Member Mapping
	forceinline operator AllocatorInfo() { return arena_allocator_info(this); }

	forceinline static void* allocator_proc( void* allocator_data, AllocType type, ssize size, ssize alignment, void* old_memory, ssize old_size, u64 flags ) { return arena_allocator_proc( allocator_data, type, size, alignment, old_memory, old_size, flags ); }
	forceinline static Arena init_from_memory( void* start, ssize size )                                                                                      { return arena_init_from_memory( start, size ); }
	forceinline static Arena init_from_allocator( AllocatorInfo backing, ssize size )                                                                         { return arena_init_from_allocator( backing, size ); }
	forceinline static Arena init_sub( Arena& parent, ssize size )                                                                                            { return arena_init_from_allocator( parent.Backing, size ); }
	forceinline        ssize alignment_of( ssize alignment )                                                                                                  { return arena_alignment_of(this, alignment); }
	forceinline        void  free()                                                                                                                           { return arena_free(this);  }
	forceinline        ssize size_remaining( ssize alignment )                                                                                                { return arena_size_remaining(this, alignment); }

// This id is defined by Unreal for asserts
#pragma push_macro("check")
#undef check
	forceinline void check() { arena_check(this); }
#pragma pop_macro("check")

#pragma endregion Member Mapping
#endif
};

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
forceinline AllocatorInfo allocator_info(Arena& arena )                 { return arena_allocator_info(& arena); }
forceinline Arena         init_sub      (Arena& parent, ssize size)     { return arena_init_sub( & parent, size); }
forceinline ssize         alignment_of  (Arena& arena, ssize alignment) { return arena_alignment_of( & arena, alignment); }
forceinline void          free          (Arena& arena)                  { return arena_free(& arena); }
forceinline ssize         size_remaining(Arena& arena, ssize alignment) { return arena_size_remaining(& arena, alignment); }

// This id is defined by Unreal for asserts
#pragma push_macro("check")
#undef check
forceinline void check(Arena& arena) { return arena_check(& arena); }
#pragma pop_macro("check")
#endif

inline
AllocatorInfo arena_allocator_info( Arena* arena ) {
	GEN_ASSERT(arena != nullptr);
	AllocatorInfo info = { arena_allocator_proc, arena };
	return info;
}

inline
Arena arena_init_from_memory( void* start, ssize size )
{
	Arena arena = {
		{ nullptr, nullptr },
		start,
		size,
		0,
		0
	};
	return arena;
}

inline
Arena arena_init_from_allocator(AllocatorInfo backing, ssize size) {
	Arena result = {
		backing,
		alloc(backing, size),
		size,
		0,
		0
	};
	return result;
}

inline
Arena arena_init_sub(Arena* parent, ssize size) {
	GEN_ASSERT(parent != nullptr);
	return arena_init_from_allocator(parent->Backing, size);
}

inline
ssize arena_alignment_of(Arena* arena, ssize alignment)
{
	GEN_ASSERT(arena != nullptr);
	ssize alignment_offset, result_pointer, mask;
	GEN_ASSERT(is_power_of_two(alignment));

	alignment_offset = 0;
	result_pointer  = (ssize)arena->PhysicalStart + arena->TotalUsed;
	mask            = alignment - 1;

	if (result_pointer & mask)
	alignment_offset = alignment - (result_pointer & mask);

	return alignment_offset;
}

inline
void arena_check(Arena* arena)
{
    GEN_ASSERT(arena != nullptr );
    GEN_ASSERT(arena->TempCount == 0);
}

inline
void arena_free(Arena* arena)
{
	GEN_ASSERT(arena != nullptr);
	if (arena->Backing.Proc)
	{
		allocator_free(arena->Backing, arena->PhysicalStart);
		arena->PhysicalStart = nullptr;
	}
}

inline
ssize arena_size_remaining(Arena* arena, ssize alignment)
{
	GEN_ASSERT(arena != nullptr);
	ssize result = arena->TotalSize - (arena->TotalUsed + arena_alignment_of(arena, alignment));
	return result;
}
#pragma endregion Arena

#pragma region FixedArena
template<s32 Size>
struct FixedArena;

template<s32 Size> FixedArena<Size> fixed_arena_init();
template<s32 Size> AllocatorInfo    fixed_arena_allocator_info(FixedArena<Size>* fixed_arena );
template<s32 Size> ssize            fixed_arena_size_remaining(FixedArena<Size>* fixed_arena, ssize alignment);
template<s32 Size> void             fixed_arena_free(FixedArena<Size>* fixed_arena);

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
template<s32 Size> AllocatorInfo    allocator_info( FixedArena<Size>& fixed_arena )                { return allocator_info(& fixed_arena); }
template<s32 Size> ssize            size_remaining(FixedArena<Size>& fixed_arena, ssize alignment) { return size_remaining( & fixed_arena, alignment); }
#endif

// Just a wrapper around using an arena with memory associated with its scope instead of from an allocator.
// Used for static segment or stack allocations.
template< s32 Size >
struct FixedArena
{
	char  memory[Size];
	Arena arena;

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
#pragma region Member Mapping
	forceinline operator AllocatorInfo() { return fixed_arena_allocator_info(this); }

	forceinline static FixedArena init()                          { FixedArena result; fixed_arena_init<Size>(result); return result; }
	forceinline ssize             size_remaining(ssize alignment) { fixed_arena_size_remaining(this, alignment); }
#pragma endregion Member Mapping
#endif
};

template<s32 Size> inline
AllocatorInfo fixed_arena_allocator_info( FixedArena<Size>* fixed_arena ) {
	GEN_ASSERT(fixed_arena);
	return { arena_allocator_proc, & fixed_arena->arena };
}

template<s32 Size> inline
void fixed_arena_init(FixedArena<Size>* result) {
    zero_size(& result->memory[0], Size);
    result->arena = arena_init_from_memory(& result->memory[0], Size);
}

template<s32 Size> inline
void fixed_arena_free(FixedArena<Size>* fixed_arena) {
	arena_free( & fixed_arena->arena);
}

template<s32 Size> inline
ssize fixed_arena_size_remaining(FixedArena<Size>* fixed_arena, ssize alignment) {
    return size_remaining(fixed_arena->arena, alignment);
}

using FixedArena_1KB   = FixedArena< kilobytes( 1 ) >;
using FixedArena_4KB   = FixedArena< kilobytes( 4 ) >;
using FixedArena_8KB   = FixedArena< kilobytes( 8 ) >;
using FixedArena_16KB  = FixedArena< kilobytes( 16 ) >;
using FixedArena_32KB  = FixedArena< kilobytes( 32 ) >;
using FixedArena_64KB  = FixedArena< kilobytes( 64 ) >;
using FixedArena_128KB = FixedArena< kilobytes( 128 ) >;
using FixedArena_256KB = FixedArena< kilobytes( 256 ) >;
using FixedArena_512KB = FixedArena< kilobytes( 512 ) >;
using FixedArena_1MB   = FixedArena< megabytes( 1 ) >;
using FixedArena_2MB   = FixedArena< megabytes( 2 ) >;
using FixedArena_4MB   = FixedArena< megabytes( 4 ) >;
#pragma endregion FixedArena

#pragma region Pool
struct Pool;

GEN_API void* pool_allocator_proc(void* allocator_data, AllocType type, ssize size, ssize alignment, void* old_memory, ssize old_size, u64 flags);

        Pool          pool_init(AllocatorInfo backing, ssize num_blocks, ssize block_size);
        Pool          pool_init_align(AllocatorInfo backing, ssize num_blocks, ssize block_size, ssize block_align);
        AllocatorInfo pool_allocator_info(Pool* pool);
GEN_API void          pool_clear(Pool* pool);
        void          pool_free(Pool* pool);

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
forceinline AllocatorInfo allocator_info(Pool& pool) { return pool_allocator_info(& pool); }
forceinline void          clear(Pool& pool)          { return pool_clear(& pool); }
forceinline void          free(Pool& pool)           { return pool_free(& pool); }
#endif

struct Pool
{
	AllocatorInfo Backing;
	void*         PhysicalStart;
	void*         FreeList;
	ssize         BlockSize;
	ssize         BlockAlign;
	ssize         TotalSize;
	ssize         NumBlocks;

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
#pragma region Member Mapping
    forceinline operator AllocatorInfo() { return pool_allocator_info(this); }

    forceinline static void* allocator_proc(void* allocator_data, AllocType type, ssize size, ssize alignment, void* old_memory, ssize old_size, u64 flags) { return pool_allocator_proc(allocator_data, type, size, alignment, old_memory, old_size, flags); }
    forceinline static Pool  init(AllocatorInfo backing, ssize num_blocks, ssize block_size)                                                                { return pool_init(backing, num_blocks, block_size); }
    forceinline static Pool  init_align(AllocatorInfo backing, ssize num_blocks, ssize block_size, ssize block_align)                                       { return pool_init_align(backing, num_blocks, block_size, block_align); }
    forceinline        void  clear() { pool_clear( this); }
    forceinline        void  free()  { pool_free( this); }
#pragma endregion
#endif
};

inline
AllocatorInfo pool_allocator_info(Pool* pool) {
	AllocatorInfo info = { pool_allocator_proc, pool };
	return info;
}

inline
Pool pool_init(AllocatorInfo backing, ssize num_blocks, ssize block_size) {
	return pool_init_align(backing, num_blocks, block_size, GEN_DEFAULT_MEMORY_ALIGNMENT);
}

inline
void pool_free(Pool* pool) {
	if(pool->Backing.Proc) {
		allocator_free(pool->Backing, pool->PhysicalStart);
	}
}
#pragma endregion Pool

inline
b32 is_power_of_two( ssize x ) {
	if ( x <= 0 )
		return false;
	return ! ( x & ( x - 1 ) );
}

inline
mem_ptr align_forward( void* ptr, ssize alignment )
{
	GEN_ASSERT( is_power_of_two( alignment ) );
	uptr p       = to_uptr(ptr);
	uptr forward = (p + ( alignment - 1 ) ) & ~( alignment - 1 );

	return to_mem_ptr(forward);
}

inline s64 align_forward_s64( s64 value, ssize alignment ) { return value + ( alignment - value % alignment ) % alignment; }

inline void*       pointer_add      ( void*       ptr, ssize bytes ) { return rcast(void*,         rcast( u8*,        ptr) + bytes ); }
inline void const* pointer_add_const( void const* ptr, ssize bytes ) { return rcast(void const*, rcast( u8 const*,  ptr) + bytes ); }

inline sptr pointer_diff( mem_ptr_const begin, mem_ptr_const end ) {
	return scast( ssize, rcast( u8 const*, end) - rcast(u8 const*, begin) );
}

inline
void* mem_move( void* destination, void const* source, ssize byte_count )
{
	if ( destination == NULL )
	{
		return NULL;
	}

	u8*       dest_ptr = rcast( u8*, destination);
	u8 const* src_ptr  = rcast( u8 const*, source);

	if ( dest_ptr == src_ptr )
		return dest_ptr;

	if ( src_ptr + byte_count <= dest_ptr || dest_ptr + byte_count <= src_ptr )    // NOTE: Non-overlapping
		return mem_copy( dest_ptr, src_ptr, byte_count );

	if ( dest_ptr < src_ptr )
	{
		if ( to_uptr(src_ptr) % size_of( ssize ) == to_uptr(dest_ptr) % size_of( ssize ) )
		{
			while ( pcast( uptr, dest_ptr) % size_of( ssize ) )
			{
				if ( ! byte_count-- )
					return destination;

				*dest_ptr++ = *src_ptr++;
			}
			while ( byte_count >= size_of( ssize ) )
			{
				* rcast(ssize*, dest_ptr)  = * rcast(ssize const*, src_ptr);
				byte_count -= size_of( ssize );
				dest_ptr   += size_of( ssize );
				src_ptr    += size_of( ssize );
			}
		}
		for ( ; byte_count; byte_count-- )
			*dest_ptr++ = *src_ptr++;
	}
	else
	{
		if ( ( to_uptr(src_ptr) % size_of( ssize ) ) == ( to_uptr(dest_ptr) % size_of( ssize ) ) )
		{
			while ( to_uptr( dest_ptr + byte_count ) % size_of( ssize ) )
			{
				if ( ! byte_count-- )
					return destination;

				dest_ptr[ byte_count ] = src_ptr[ byte_count ];
			}
			while ( byte_count >= size_of( ssize ) )
			{
				byte_count                              -= size_of( ssize );
				* rcast(ssize*, dest_ptr + byte_count )  = * rcast( ssize const*, src_ptr + byte_count );
			}
		}
		while ( byte_count )
			byte_count--, dest_ptr[ byte_count ] = src_ptr[ byte_count ];
	}

	return destination;
}

inline
void* mem_set( void* destination, u8 fill_byte, ssize byte_count )
{
	if ( destination == NULL )
	{
		return NULL;
	}

	ssize align_offset;
	u8*   dest_ptr  = rcast( u8*, destination);
	u32   fill_word = ( ( u32 )-1 ) / 255 * fill_byte;

	if ( byte_count == 0 )
		return destination;

	dest_ptr[ 0 ] = dest_ptr[ byte_count - 1 ] = fill_byte;
	if ( byte_count < 3 )
		return destination;

	dest_ptr[ 1 ] = dest_ptr[ byte_count - 2 ] = fill_byte;
	dest_ptr[ 2 ] = dest_ptr[ byte_count - 3 ] = fill_byte;
	if ( byte_count < 7 )
		return destination;

	dest_ptr[ 3 ] = dest_ptr[ byte_count - 4 ] = fill_byte;
	if ( byte_count < 9 )
		return destination;

	align_offset  = -to_sptr( dest_ptr ) & 3;
	dest_ptr     += align_offset;
	byte_count   -= align_offset;
	byte_count   &= -4;

	* rcast( u32*, ( dest_ptr + 0              ) ) = fill_word;
	* rcast( u32*, ( dest_ptr + byte_count - 4 ) ) = fill_word;
	if ( byte_count < 9 )
		return destination;

	* rcast( u32*, dest_ptr + 4 )               = fill_word;
	* rcast( u32*, dest_ptr + 8 )               = fill_word;
	* rcast( u32*, dest_ptr + byte_count - 12 ) = fill_word;
	* rcast( u32*, dest_ptr + byte_count - 8 )  = fill_word;
	if ( byte_count < 25 )
		return destination;

	* rcast( u32*, dest_ptr + 12 )              = fill_word;
	* rcast( u32*, dest_ptr + 16 )              = fill_word;
	* rcast( u32*, dest_ptr + 20 )              = fill_word;
	* rcast( u32*, dest_ptr + 24 )              = fill_word;
	* rcast( u32*, dest_ptr + byte_count - 28 ) = fill_word;
	* rcast( u32*, dest_ptr + byte_count - 24 ) = fill_word;
	* rcast( u32*, dest_ptr + byte_count - 20 ) = fill_word;
	* rcast( u32*, dest_ptr + byte_count - 16 ) = fill_word;

	align_offset  = 24 + to_uptr( dest_ptr ) & 4;
	dest_ptr     += align_offset;
	byte_count   -= align_offset;

	{
		u64 fill_doubleword = ( scast( u64, fill_word) << 32 ) | fill_word;
		while ( byte_count > 31 )
		{
			* rcast( u64*, dest_ptr + 0 )  = fill_doubleword;
			* rcast( u64*, dest_ptr + 8 )  = fill_doubleword;
			* rcast( u64*, dest_ptr + 16 ) = fill_doubleword;
			* rcast( u64*, dest_ptr + 24 ) = fill_doubleword;

			byte_count -= 32;
			dest_ptr += 32;
		}
	}

	return destination;
}

inline
void* alloc_align( AllocatorInfo a, ssize size, ssize alignment ) {
	return a.Proc( a.Data, EAllocation_ALLOC, size, alignment, nullptr, 0, GEN_DEFAULT_ALLOCATOR_FLAGS );
}

inline
void* alloc( AllocatorInfo a, ssize size ) {
	return alloc_align( a, size, GEN_DEFAULT_MEMORY_ALIGNMENT );
}

inline
void allocator_free( AllocatorInfo a, void* ptr ) {
	if ( ptr != nullptr )
		a.Proc( a.Data, EAllocation_FREE, 0, 0, ptr, 0, GEN_DEFAULT_ALLOCATOR_FLAGS );
}

inline
void free_all( AllocatorInfo a ) {
	a.Proc( a.Data, EAllocation_FREE_ALL, 0, 0, nullptr, 0, GEN_DEFAULT_ALLOCATOR_FLAGS );
}

inline
void* resize( AllocatorInfo a, void* ptr, ssize old_size, ssize new_size ) {
	return resize_align( a, ptr, old_size, new_size, GEN_DEFAULT_MEMORY_ALIGNMENT );
}

inline
void* resize_align( AllocatorInfo a, void* ptr, ssize old_size, ssize new_size, ssize alignment ) {
	return a.Proc( a.Data, EAllocation_RESIZE, new_size, alignment, ptr, old_size, GEN_DEFAULT_ALLOCATOR_FLAGS );
}

inline
void* default_resize_align( AllocatorInfo a, void* old_memory, ssize old_size, ssize new_size, ssize alignment )
{
	if ( ! old_memory )
		return alloc_align( a, new_size, alignment );

	if ( new_size == 0 )
	{
		allocator_free( a, old_memory );
		return nullptr;
	}

	if ( new_size < old_size )
		new_size = old_size;

	if ( old_size == new_size )
	{
		return old_memory;
	}
	else
	{
		void*  new_memory = alloc_align( a, new_size, alignment );
		if ( ! new_memory )
			return nullptr;

		mem_move( new_memory, old_memory, min( new_size, old_size ) );
		allocator_free( a, old_memory );
		return new_memory;
	}
}

inline
void zero_size( void* ptr, ssize size ) {
	mem_set( ptr, 0, size );
}

#pragma endregion Memory

#pragma region String Ops

const char* char_first_occurence( const char* str, char c );

b32   char_is_alpha( char c );
b32   char_is_alphanumeric( char c );
b32   char_is_digit( char c );
b32   char_is_hex_digit( char c );
b32   char_is_space( char c );
char  char_to_lower( char c );
char  char_to_upper( char c );

s32  digit_to_int( char c );
s32  hex_digit_to_int( char c );

s32         c_str_compare( const char* s1, const char* s2 );
s32         c_str_compare_len( const char* s1, const char* s2, ssize len );
char*       c_str_copy( char* dest, const char* source, ssize len );
ssize       c_str_copy_nulpad( char* dest, const char* source, ssize len );
ssize       c_str_len( const char* str );
ssize       c_str_len_capped( const char* str, ssize max_len );
char*       c_str_reverse( char* str );    // NOTE: ASCII only
char const* c_str_skip( char const* str, char c );
char const* c_str_skip_any( char const* str, char const* char_list );
char const* c_str_trim( char const* str, b32 catch_newline );

// NOTE: ASCII only
void c_str_to_lower( char* str );
void c_str_to_upper( char* str );

GEN_API s64  c_str_to_i64( const char* str, char** end_ptr, s32 base );
GEN_API void i64_to_str( s64 value, char* string, s32 base );
GEN_API void u64_to_str( u64 value, char* string, s32 base );
GEN_API f64  c_str_to_f64( const char* str, char** end_ptr );

inline
const char* char_first_occurence( const char* s, char c )
{
	char ch = c;
	for ( ; *s != ch; s++ )
	{
		if ( *s == '\0' )
			return NULL;
	}
	return s;
}

inline
b32 char_is_alpha( char c )
{
	if ( ( c >= 'A' && c <= 'Z' ) || ( c >= 'a' && c <= 'z' ) )
		return true;
	return false;
}

inline
b32 char_is_alphanumeric( char c )
{
	return char_is_alpha( c ) || char_is_digit( c );
}

inline
b32 char_is_digit( char c )
{
	if ( c >= '0' && c <= '9' )
		return true;
	return false;
}

inline
b32 char_is_hex_digit( char c )
{
	if ( char_is_digit( c ) || ( c >= 'a' && c <= 'f' ) || ( c >= 'A' && c <= 'F' ) )
		return true;
	return false;
}

inline
b32 char_is_space( char c )
{
	if ( c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' || c == '\v' )
		return true;
	return false;
}

inline
char char_to_lower( char c )
{
	if ( c >= 'A' && c <= 'Z' )
		return 'a' + ( c - 'A' );
	return c;
}

inline char char_to_upper( char c )
{
	if ( c >= 'a' && c <= 'z' )
		return 'A' + ( c - 'a' );
	return c;
}

inline
s32 digit_to_int( char c )
{
	return char_is_digit( c ) ? c - '0' : c - 'W';
}

inline
s32 hex_digit_to_int( char c )
{
	if ( char_is_digit( c ) )
		return digit_to_int( c );
	else if ( is_between( c, 'a', 'f' ) )
		return c - 'a' + 10;
	else if ( is_between( c, 'A', 'F' ) )
		return c - 'A' + 10;
	return -1;
}

inline
s32 c_str_compare( const char* s1, const char* s2 )
{
	while ( *s1 && ( *s1 == *s2 ) )
	{
		s1++, s2++;
	}
	return *( u8* )s1 - *( u8* )s2;
}

inline
s32 c_str_compare_len( const char* s1, const char* s2, ssize len )
{
	for ( ; len > 0; s1++, s2++, len-- )
	{
		if ( *s1 != *s2 )
			return ( ( s1 < s2 ) ? -1 : +1 );
		else if ( *s1 == '\0' )
			return 0;
	}
	return 0;
}

inline
char* c_str_copy( char* dest, const char* source, ssize len )
{
	GEN_ASSERT_NOT_NULL( dest );
	if ( source )
	{
		char* str = dest;
		while ( len > 0 && *source )
		{
			*str++ = *source++;
			len--;
		}
		while ( len > 0 )
		{
			*str++ = '\0';
			len--;
		}
	}
	return dest;
}

inline
ssize c_str_copy_nulpad( char* dest, const char* source, ssize len )
{
	ssize result = 0;
	GEN_ASSERT_NOT_NULL( dest );
	if ( source )
	{
		const char* source_start = source;
		char*       str          = dest;
		while ( len > 0 && *source )
		{
			*str++ = *source++;
			len--;
		}
		while ( len > 0 )
		{
			*str++ = '\0';
			len--;
		}

		result = source - source_start;
	}
	return result;
}

inline
ssize c_str_len( const char* str )
{
	if ( str == NULL )
	{
		return 0;
	}
	const char* p = str;
	while ( *str )
		str++;
	return str - p;
}

inline
ssize c_str_len_capped( const char* str, ssize max_len )
{
	const char* end = rcast(const char*, mem_find( str, 0, max_len ));
	if ( end )
		return end - str;
	return max_len;
}

inline
char* c_str_reverse( char* str )
{
	ssize    len  = c_str_len( str );
	char* a    = str + 0;
	char* b    = str + len - 1;
	len       /= 2;
	while ( len-- )
	{
		swap( *a, *b );
		a++, b--;
	}
	return str;
}

inline
char const* c_str_skip( char const* str, char c )
{
	while ( *str && *str != c )
	{
		++str;
	}
	return str;
}

inline
char const* c_str_skip_any( char const* str, char const* char_list )
{
	char const* closest_ptr     = rcast( char const*, pointer_add_const( rcast(mem_ptr_const, str), c_str_len( str ) ));
	ssize       char_list_count = c_str_len( char_list );
	for ( ssize i = 0; i < char_list_count; i++ )
	{
		char const* p = c_str_skip( str, char_list[ i ] );
		closest_ptr   = min( closest_ptr, p );
	}
	return closest_ptr;
}

inline
char const* c_str_trim( char const* str, b32 catch_newline )
{
	while ( *str && char_is_space( *str ) && ( ! catch_newline || ( catch_newline && *str != '\n' ) ) )
	{
		++str;
	}
	return str;
}

inline
void c_str_to_lower( char* str )
{
	if ( ! str )
		return;
	while ( *str )
	{
		*str = char_to_lower( *str );
		str++;
	}
}

inline
void c_str_to_upper( char* str )
{
	if ( ! str )
		return;
	while ( *str )
	{
		*str = char_to_upper( *str );
		str++;
	}
}

#pragma endregion String Ops

#pragma region Printing

typedef struct FileInfo FileInfo;

#ifndef GEN_PRINTF_MAXLEN
#	define GEN_PRINTF_MAXLEN kilobytes(128)
#endif
typedef char PrintF_Buffer[GEN_PRINTF_MAXLEN];

// NOTE: A locally persisting buffer is used internally
GEN_API char*  c_str_fmt_buf       ( char const* fmt, ... );
GEN_API char*  c_str_fmt_buf_va    ( char const* fmt, va_list va );
GEN_API ssize  c_str_fmt           ( char* str, ssize n, char const* fmt, ... );
GEN_API ssize  c_str_fmt_va        ( char* str, ssize n, char const* fmt, va_list va );
GEN_API ssize  c_str_fmt_out_va    ( char const* fmt, va_list va );
GEN_API ssize  c_str_fmt_out_err   ( char const* fmt, ... );
GEN_API ssize  c_str_fmt_out_err_va( char const* fmt, va_list va );
GEN_API ssize  c_str_fmt_file      ( FileInfo* f, char const* fmt, ... );
GEN_API ssize  c_str_fmt_file_va   ( FileInfo* f, char const* fmt, va_list va );

constexpr
char const* Msg_Invalid_Value = "INVALID VALUE PROVIDED";

inline
ssize log_fmt(char const* fmt, ...)
{
	ssize res;
	va_list va;

	va_start(va, fmt);
	res = c_str_fmt_out_va(fmt, va);
	va_end(va);

	return res;
}

#pragma endregion Printing

#pragma region Containers

template<class TType>             struct RemoveConst                    { typedef TType Type;       };
template<class TType>             struct RemoveConst<const TType>       { typedef TType Type;       };
template<class TType>             struct RemoveConst<const TType[]>     { typedef TType Type[];     };
template<class TType, usize Size> struct RemoveConst<const TType[Size]> { typedef TType Type[Size]; };

template<class TType> using TRemoveConst = typename RemoveConst<TType>::Type;

template <class TType> struct RemovePtr         { typedef TType Type; };
template <class TType> struct RemovePtr<TType*> { typedef TType Type; };

template <class TType> using TRemovePtr = typename RemovePtr<TType>::Type;


#pragma region Array
#define Array(Type) Array<Type>

// #define array_init(Type, ...)         array_init        <Type>(__VA_ARGS__)
// #define array_init_reserve(Type, ...) array_init_reserve<Type>(__VA_ARGS__)

struct ArrayHeader;

#if GEN_COMPILER_CPP
	template<class Type> struct Array;
#	define get_array_underlying_type(array) typename TRemovePtr<typeof(array)>:: DataType
#endif

usize array_grow_formula(ssize value);

template<class Type> Array<Type>  array_init           (AllocatorInfo allocator);
template<class Type> Array<Type>  array_init_reserve   (AllocatorInfo allocator, ssize capacity);
template<class Type> bool         array_append_array   (Array<Type>* array, Array<Type> other);
template<class Type> bool         array_append         (Array<Type>* array, Type value);
template<class Type> bool         array_append_items   (Array<Type>* array, Type* items, usize item_num);
template<class Type> bool         array_append_at      (Array<Type>* array, Type item, usize idx);
template<class Type> bool         array_append_items_at(Array<Type>* array, Type* items, usize item_num, usize idx);
template<class Type> Type*        array_back           (Array<Type>  array);
template<class Type> void         array_clear          (Array<Type>  array);
template<class Type> bool         array_fill           (Array<Type>  array, usize begin, usize end, Type value);
template<class Type> void         array_free           (Array<Type>* array);
template<class Type> bool         arary_grow           (Array<Type>* array, usize min_capacity);
template<class Type> usize        array_num            (Array<Type>  array);
template<class Type> void         arary_pop            (Array<Type>  array);
template<class Type> void         arary_remove_at      (Array<Type>  array, usize idx);
template<class Type> bool         arary_reserve        (Array<Type>* array, usize new_capacity);
template<class Type> bool         arary_resize         (Array<Type>* array, usize num);
template<class Type> bool         arary_set_capacity   (Array<Type>* array, usize new_capacity);
template<class Type> ArrayHeader* arary_get_header     (Array<Type>  array);

struct ArrayHeader {
	AllocatorInfo Allocator;
	usize         Capacity;
	usize         Num;
};

#if GEN_COMPILER_CPP
template<class Type>
struct Array
{
	Type* Data;

#pragma region Member Mapping
	forceinline static Array  init(AllocatorInfo allocator)                         { return array_init<Type>(allocator); }
	forceinline static Array  init_reserve(AllocatorInfo allocator, ssize capacity) { return array_init_reserve<Type>(allocator, capacity); }
	forceinline static usize  grow_formula(ssize value)                             { return array_grow_formula<Type>(value); }

	forceinline bool         append(Array other)                               { return array_append_array<Type>(this, other); }
	forceinline bool         append(Type value)                                { return array_append<Type>(this, value); }
	forceinline bool         append(Type* items, usize item_num)               { return array_append_items<Type>(this, items, item_num); }
	forceinline bool         append_at(Type item, usize idx)                   { return array_append_at<Type>(this, item, idx); }
	forceinline bool         append_at(Type* items, usize item_num, usize idx) { return array_append_items_at<Type>(this, items, item_num, idx); }
	forceinline Type*        back()                                            { return array_back<Type>(* this); }
	forceinline void         clear()                                           {        array_clear<Type>(* this); }
	forceinline bool         fill(usize begin, usize end, Type value)          { return array_fill<Type>(* this, begin, end, value); }
	forceinline void         free()                                            {        array_free<Type>(this); }
	forceinline ArrayHeader* get_header()                                      { return array_get_header<Type>(* this); }
	forceinline bool         grow(usize min_capacity)                          { return array_grow<Type>(this, min_capacity); }
	forceinline usize        num()                                             { return array_num<Type>(*this); }
	forceinline void         pop()                                             {        array_pop<Type>(* this); }
	forceinline void         remove_at(usize idx)                              {        array_remove_at<Type>(* this, idx); }
	forceinline bool         reserve(usize new_capacity)                       { return array_reserve<Type>(this, new_capacity); }
	forceinline bool         resize(usize num)                                 { return array_resize<Type>(this, num); }
	forceinline bool         set_capacity(usize new_capacity)                  { return array_set_capacity<Type>(this, new_capacity); }
#pragma endregion Member Mapping

	forceinline operator Type*()             { return Data; }
	forceinline operator Type const*() const { return Data; }
	forceinline Type* begin()                { return Data; }
	forceinline Type* end()                  { return Data + get_header()->Num; }

	forceinline Type&       operator[](ssize index)       { return Data[index]; }
	forceinline Type const& operator[](ssize index) const { return Data[index]; }

	using DataType = Type;
};
#endif

#if GEN_COMPILER_CPP && 0
template<class Type> bool append(Array<Type>& array, Array<Type> other)                         { return append( & array, other ); }
template<class Type> bool append(Array<Type>& array, Type value)                                { return append( & array, value ); }
template<class Type> bool append(Array<Type>& array, Type* items, usize item_num)               { return append( & array, items, item_num ); }
template<class Type> bool append_at(Array<Type>& array, Type item, usize idx)                   { return append_at( & array, item, idx ); }
template<class Type> bool append_at(Array<Type>& array, Type* items, usize item_num, usize idx) { return append_at( & array, items, item_num, idx ); }
template<class Type> void free(Array<Type>& array)                                              { return free( & array ); }
template<class Type> bool grow(Array<Type>& array, usize min_capacity)                          { return grow( & array, min_capacity); }
template<class Type> bool reserve(Array<Type>& array, usize new_capacity)                       { return reserve( & array, new_capacity); }
template<class Type> bool resize(Array<Type>& array, usize num)                                 { return resize( & array, num); }
template<class Type> bool set_capacity(Array<Type>& array, usize new_capacity)                  { return set_capacity( & array, new_capacity); }

template<class Type> forceinline Type* begin(Array<Type>& array)             { return array;      }
template<class Type> forceinline Type* end(Array<Type>& array)               { return array + array_get_header(array)->Num; }
template<class Type> forceinline Type* next(Array<Type>& array, Type* entry) { return entry + 1; }
#endif

template<class Type> forceinline Type* array_begin(Array<Type> array)             { return array;      }
template<class Type> forceinline Type* array_end(Array<Type> array)               { return array + array_get_header(array)->Num; }
template<class Type> forceinline Type* array_next(Array<Type> array, Type* entry) { return ++ entry; }

template<class Type> inline
Array<Type> array_init(AllocatorInfo allocator) {
	return array_init_reserve<Type>(allocator, array_grow_formula(0));
}

template<class Type> inline
Array<Type> array_init_reserve(AllocatorInfo allocator, ssize capacity)
{
	GEN_ASSERT(capacity > 0);
	ArrayHeader* header = rcast(ArrayHeader*, alloc(allocator, sizeof(ArrayHeader) + sizeof(Type) * capacity));

	if (header == nullptr)
		return {nullptr};

	header->Allocator = allocator;
	header->Capacity  = capacity;
	header->Num       = 0;

	return {rcast(Type*, header + 1)};
}

forceinline
usize array_grow_formula(ssize value) {
	return 2 * value + 8;
}

template<class Type> inline
bool array_append_array(Array<Type>* array, Array<Type> other) {
	return array_append_items(array, (Type*)other, array_num(other));
}

template<class Type> inline
bool array_append(Array<Type>* array, Type value)
{
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	ArrayHeader* header = array_get_header(* array);

	if (header->Num == header->Capacity)
	{
		if ( ! array_grow(array, header->Capacity))
			return false;
		header = array_get_header(* array);
	}

	(*array)[ header->Num] = value;
	header->Num++;

	return true;
}

template<class Type> inline
bool array_append_items(Array<Type>* array, Type* items, usize item_num)
{
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	GEN_ASSERT(items != nullptr);
	GEN_ASSERT(item_num > 0);
	ArrayHeader* header = array_get_header(* array);

	if (header->Num + item_num > header->Capacity)
	{
		if ( ! array_grow(array, header->Capacity + item_num))
			return false;
		header = array_get_header(* array);
	}

	mem_copy((Type*)array + header->Num, items, item_num * sizeof(Type));
	header->Num += item_num;

	return true;
}

template<class Type> inline
bool array_append_at(Array<Type>* array, Type item, usize idx)
{
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	ArrayHeader* header = array_get_header(* array);

	ssize slot = idx;
	if (slot >= (ssize)(header->Num))
		slot = header->Num - 1;

	if (slot < 0)
		slot = 0;

	if (header->Capacity < header->Num + 1)
	{
		if ( ! array_grow(array, header->Capacity + 1))
			return false;

		header = array_get_header(* array);
	}

	Type* target = &(*array)[slot];

	mem_move(target + 1, target, (header->Num - slot) * sizeof(Type));
	header->Num++;

	return true;
}

template<class Type> inline
bool array_append_items_at(Array<Type>* array, Type* items, usize item_num, usize idx)
{
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	ArrayHeader* header = get_header(array);

	if (idx >= header->Num)
	{
		return array_append_items(array, items, item_num);
	}

	if (item_num > header->Capacity)
	{
		if (! grow(array, header->Capacity + item_num))
			return false;

		header = get_header(array);
	}

	Type* target = array.Data + idx + item_num;
	Type* src    = array.Data + idx;

	mem_move(target, src, (header->Num - idx) * sizeof(Type));
	mem_copy(src, items, item_num * sizeof(Type));
	header->Num += item_num;

	return true;
}

template<class Type> inline
Type* array_back(Array<Type> array)
{
	GEN_ASSERT(array != nullptr);

	ArrayHeader* header = array_get_header(array);
	if (header->Num <= 0)
		return nullptr;

	return & (array)[header->Num - 1];
}

template<class Type> inline
void array_clear(Array<Type> array) {
	GEN_ASSERT(array != nullptr);
	ArrayHeader* header = array_get_header(array);
	header->Num = 0;
}

template<class Type> inline
bool array_fill(Array<Type> array, usize begin, usize end, Type value)
{
	GEN_ASSERT(array != nullptr);
	GEN_ASSERT(begin <= end);
	ArrayHeader* header = array_get_header(array);

	if (begin < 0 || end > header->Num)
		return false;

	for (ssize idx = ssize(begin); idx < ssize(end); idx++) {
		array[idx] = value;
	}

	return true;
}

template<class Type> forceinline
void array_free(Array<Type>* array) {
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	ArrayHeader* header = array_get_header(* array);
	allocator_free(header->Allocator, header);
	Type** Data = (Type**)array;
	*Data = nullptr;
}

template<class Type> forceinline
ArrayHeader* array_get_header(Array<Type> array) {
	GEN_ASSERT(array != nullptr);
    Type* Data = array;

	using NonConstType = TRemoveConst<Type>;
    return rcast(ArrayHeader*, const_cast<NonConstType*>(Data)) - 1;
}

template<class Type> forceinline
bool array_grow(Array<Type>* array, usize min_capacity)
{
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	GEN_ASSERT( min_capacity > 0 );
	ArrayHeader* header       = array_get_header(* array);
	usize        new_capacity = array_grow_formula(header->Capacity);

	if (new_capacity < min_capacity)
		new_capacity = min_capacity;

	return array_set_capacity(array, new_capacity);
}

template<class Type> forceinline
usize array_num(Array<Type> array) {
	GEN_ASSERT(array != nullptr);
	return array_get_header(array)->Num;
}

template<class Type> forceinline
void array_pop(Array<Type> array) {
	GEN_ASSERT(array != nullptr);
	ArrayHeader* header = array_get_header(array);
	GEN_ASSERT(header->Num > 0);
	header->Num--;
}

template<class Type> inline
void array_remove_at(Array<Type> array, usize idx)
{
	GEN_ASSERT(array != nullptr);
	ArrayHeader* header = array_get_header(array);
	GEN_ASSERT(idx < header->Num);

	mem_move(array + idx, array + idx + 1, sizeof(Type) * (header->Num - idx - 1));
	header->Num--;
}

template<class Type> inline
bool array_reserve(Array<Type>* array, usize new_capacity)
{
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	ArrayHeader* header = array_get_header(array);

	if (header->Capacity < new_capacity)
		return set_capacity(array, new_capacity);

	return true;
}

template<class Type> inline
bool array_resize(Array<Type>* array, usize num)
{
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	ArrayHeader* header = array_get_header(* array);

	if (header->Capacity < num) {
		if (! array_grow( array, num))
			return false;
		header = array_get_header(* array);
	}

	header->Num = num;
	return true;
}

template<class Type> inline
bool array_set_capacity(Array<Type>* array, usize new_capacity)
{
	GEN_ASSERT(  array != nullptr);
	GEN_ASSERT(* array != nullptr);
	ArrayHeader* header = array_get_header(* array);

	if (new_capacity == header->Capacity)
		return true;

	if (new_capacity < header->Num)
	{
		header->Num = new_capacity;
		return true;
	}

	ssize        size       = sizeof(ArrayHeader) + sizeof(Type) * new_capacity;
	ArrayHeader* new_header = rcast(ArrayHeader*, alloc(header->Allocator, size));

	if (new_header == nullptr)
		return false;

	mem_move(new_header, header, sizeof(ArrayHeader) + sizeof(Type) * header->Num);

	new_header->Capacity = new_capacity;

	allocator_free(header->Allocator, header);

	Type** Data = (Type**)array;
	* Data = rcast(Type*, new_header + 1);
	return true;
}

// These are intended for use in the base library of gencpp and the C-variant of the library
// It provides a interoperability between the C++ and C implementation of arrays. (not letting these do any crazy substiution though)
// They are undefined in gen.hpp and gen.cpp at the end of the files.
// The cpp library expects the user to use the regular calls as they can resolve the type fine.

#define array_init(type, allocator)                        array_init           <type>                               (allocator )
#define array_init_reserve(type, allocator, cap)           array_init_reserve   <type>                               (allocator, cap)
#define array_append_array(array, other)                   array_append_array   < get_array_underlying_type(array) > (& array, other )
#define array_append(array, value)                         array_append         < get_array_underlying_type(array) > (& array, value )
#define array_append_items(array, items, item_num)         array_append_items   < get_array_underlying_type(array) > (& array, items, item_num )
#define array_append_at(array, item, idx )                 array_append_at      < get_array_underlying_type(array) > (& array, item, idx )
#define array_append_at_items(array, items, item_num, idx) array_append_at_items< get_array_underlying_type(array) > (& items, item_num, idx )
#define array_back(array)                                  array_back           < get_array_underlying_type(array) > (array )
#define array_clear(array)                                 array_clear          < get_array_underlying_type(array) > (array )
#define array_fill(array, begin, end, value)               array_fill           < get_array_underlying_type(array) > (array, begin, end, value )
#define array_free(array)                                  array_free           < get_array_underlying_type(array) > (& array )
#define arary_grow(array, min_capacity)                    arary_grow           < get_array_underlying_type(array) > (& array, min_capacity)
#define array_num(array)                                   array_num            < get_array_underlying_type(array) > (array )
#define arary_pop(array)                                   arary_pop            < get_array_underlying_type(array) > (array )
#define arary_remove_at(array, idx)                        arary_remove_at      < get_array_underlying_type(array) > (idx)
#define arary_reserve(array, new_capacity)                 arary_reserve        < get_array_underlying_type(array) > (& array, new_capacity )
#define arary_resize(array, num)                           arary_resize         < get_array_underlying_type(array) > (& array, num)
#define arary_set_capacity(new_capacity)                   arary_set_capacity   < get_array_underlying_type(array) > (& array, new_capacity )
#define arary_get_header(array)                            arary_get_header     < get_array_underlying_type(array) > (array )

#pragma endregion Array

#pragma region HashTable
#define HashTable(Type) HashTable<Type>

template<class Type> struct HashTable;

#ifndef get_hashtable_underlying_type
#define get_hashtable_underlying_type(table) typename TRemovePtr<typeof(table)>:: DataType
#endif

struct HashTableFindResult {
	ssize HashIndex;
	ssize PrevIndex;
	ssize EntryIndex;
};

template<class Type>
struct HashTableEntry {
	u64   Key;
	ssize Next;
	Type  Value;
};

#define HashTableEntry(Type) HashTableEntry<Type>

template<class Type> HashTable<Type>       hashtable_init        (AllocatorInfo allocator);
template<class Type> HashTable<Type>       hashtable_init_reserve(AllocatorInfo allocator, usize num);
template<class Type> void                  hashtable_clear       (HashTable<Type>  table);
template<class Type> void                  hashtable_destroy     (HashTable<Type>* table);
template<class Type> Type*                 hashtable_get         (HashTable<Type>  table, u64 key);
template<class Type> void                  hashtable_grow        (HashTable<Type>* table);
template<class Type> void                  hashtable_rehash      (HashTable<Type>* table, ssize new_num);
template<class Type> void                  hashtable_rehash_fast (HashTable<Type>  table);
template<class Type> void                  hashtable_remove      (HashTable<Type>  table, u64 key);
template<class Type> void                  hashtable_remove_entry(HashTable<Type>  table, ssize idx);
template<class Type> void                  hashtable_set         (HashTable<Type>* table, u64 key, Type value);
template<class Type> ssize                 hashtable_slot        (HashTable<Type>  table, u64 key);
template<class Type> void                  hashtable_map         (HashTable<Type>  table, void (*map_proc)(u64 key, Type value));
template<class Type> void                  hashtable_map_mut     (HashTable<Type>  table, void (*map_proc)(u64 key, Type* value));

template<class Type> ssize                 hashtable__add_entry  (HashTable<Type>* table, u64 key);
template<class Type> HashTableFindResult   hashtable__find       (HashTable<Type>  table, u64 key);
template<class Type> bool                  hashtable__full       (HashTable<Type>  table);

static constexpr f32 HashTable_CriticalLoadScale = 0.7f;

template<typename Type>
struct HashTable
{
	Array<ssize>                Hashes;
	Array<HashTableEntry<Type>> Entries;

#if ! GEN_C_LIKE_CPP
#pragma region Member Mapping
	forceinline static HashTable init(AllocatorInfo allocator)                    { return	hashtable_init<Type>(allocator); }
	forceinline static HashTable init_reserve(AllocatorInfo allocator, usize num) { return	hashtable_init_reserve<Type>(allocator, num); }

	forceinline void  clear()                           {        clear<Type>(*this); }
	forceinline void  destroy()                         {        destroy<Type>(*this); }
	forceinline Type* get(u64 key)                      { return get<Type>(*this, key); }
	forceinline void  grow()                            {        grow<Type>(*this); }
	forceinline void  rehash(ssize new_num)             {        rehash<Type>(*this, new_num); }
	forceinline void  rehash_fast()                     {        rehash_fast<Type>(*this); }
	forceinline void  remove(u64 key)                   {        remove<Type>(*this, key); }
	forceinline void  remove_entry(ssize idx)           {        remove_entry<Type>(*this, idx); }
	forceinline void  set(u64 key, Type value)          {        set<Type>(*this, key, value); }
	forceinline ssize slot(u64 key)                     { return slot<Type>(*this, key); }
	forceinline void  map(void (*proc)(u64, Type))      {        map<Type>(*this, proc); }
	forceinline void  map_mut(void (*proc)(u64, Type*)) {        map_mut<Type>(*this, proc); }
#pragma endregion Member Mapping
#endif

	using DataType = Type;
};

#if GEN_SUPPORT_CPP_REFERENCES
template<class Type> void  destroy  (HashTable<Type>& table)                      { destroy(& table); }
template<class Type> void  grow     (HashTable<Type>& table)                      { grow(& table); }
template<class Type> void  rehash   (HashTable<Type>& table, ssize new_num)       { rehash(& table, new_num); }
template<class Type> void  set      (HashTable<Type>& table, u64 key, Type value) { set(& table, key, value); }
template<class Type> ssize add_entry(HashTable<Type>& table, u64 key)             { add_entry(& table, key); }
#endif

template<typename Type> inline
HashTable<Type> hashtable_init(AllocatorInfo allocator) {
	HashTable<Type> result = hashtable_init_reserve<Type>(allocator, 8);
	return result;
}

template<typename Type> inline
HashTable<Type> hashtable_init_reserve(AllocatorInfo allocator, usize num)
{
	HashTable<Type> result = { { nullptr }, { nullptr } };

	result.Hashes = array_init_reserve<ssize>(allocator, num);
	array_get_header(result.Hashes)->Num = num;
	array_resize(& result.Hashes, num);
	array_fill(result.Hashes, 0, num, (ssize)-1);

	result.Entries = array_init_reserve<HashTableEntry<Type>>(allocator, num);
	return result;
}

template<typename Type> forceinline
void hashtable_clear(HashTable<Type> table) {
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	array_clear(table.Entries);
	array_fill(table.Hashes, 0, array_num(table.Hashes), (ssize)-1);
}

template<typename Type> forceinline
void hashtable_destroy(HashTable<Type>* table) {
	GEN_ASSERT_NOT_NULL(table->Hashes);
	GEN_ASSERT_NOT_NULL(table->Entries);
	if (table->Hashes && array_get_header(table->Hashes)->Capacity) {
		array_free(table->Hashes);
		array_free(table->Entries);
	}
}

template<typename Type> forceinline
Type* hashtable_get(HashTable<Type> table, u64 key) {
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	ssize idx = hashtable__find(table, key).EntryIndex;
	if (idx >= 0)
		return & table.Entries[idx].Value;

	return nullptr;
}

template<typename Type> forceinline
void hashtable_map(HashTable<Type> table, void (*map_proc)(u64 key, Type value)) {
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	GEN_ASSERT_NOT_NULL(map_proc);

	for (ssize idx = 0; idx < ssize(num(table.Entries)); ++idx) {
		map_proc(table.Entries[idx].Key, table.Entries[idx].Value);
	}
}

template<typename Type> forceinline
void hashtable_map_mut(HashTable<Type> table, void (*map_proc)(u64 key, Type* value)) {
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	GEN_ASSERT_NOT_NULL(map_proc);

	for (ssize idx = 0; idx < ssize(num(table.Entries)); ++idx) {
		map_proc(table.Entries[idx].Key, & table.Entries[idx].Value);
	}
}

template<typename Type> forceinline
void hashtable_grow(HashTable<Type>* table) {
	GEN_ASSERT_NOT_NULL(table);
	GEN_ASSERT_NOT_NULL(table->Hashes);
	GEN_ASSERT_NOT_NULL(table->Entries);
	ssize new_num = array_grow_formula( array_num(table->Entries));
	hashtable_rehash(table, new_num);
}

template<typename Type> inline
void hashtable_rehash(HashTable<Type>* table, ssize new_num)
{
	GEN_ASSERT_NOT_NULL(table);
	GEN_ASSERT_NOT_NULL(table->Hashes);
	GEN_ASSERT_NOT_NULL(table->Entries);
	ssize last_added_index;
	HashTable<Type> new_ht = hashtable_init_reserve<Type>( array_get_header(table->Hashes)->Allocator, new_num);

	for (ssize idx = 0; idx < ssize( array_num(table->Entries)); ++idx)
	{
		HashTableFindResult find_result;
		HashTableEntry<Type>& entry = table->Entries[idx];

		find_result = hashtable__find(new_ht, entry.Key);
		last_added_index = hashtable__add_entry(& new_ht, entry.Key);

		if (find_result.PrevIndex < 0)
			new_ht.Hashes[find_result.HashIndex] = last_added_index;
		else
			new_ht.Entries[find_result.PrevIndex].Next = last_added_index;

		new_ht.Entries[last_added_index].Next = find_result.EntryIndex;
		new_ht.Entries[last_added_index].Value = entry.Value;
	}

	hashtable_destroy(table);
	* table = new_ht;
}

template<typename Type> inline
void hashtable_rehash_fast(HashTable<Type> table)
{
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	ssize idx;

	for (idx = 0; idx < ssize(num(table.Entries)); idx++)
		table.Entries[idx].Next = -1;

	for (idx = 0; idx < ssize(num(table.Hashes)); idx++)
		table.Hashes[idx] = -1;

	for (idx = 0; idx < ssize(num(table.Entries)); idx++)
	{
		HashTableEntry<Type>* entry;
		HashTableFindResult find_result;

		entry = &table.Entries[idx];
		find_result = find(table, entry->Key);

		if (find_result.PrevIndex < 0)
			table.Hashes[find_result.HashIndex] = idx;
		else
			table.Entries[find_result.PrevIndex].Next = idx;
	}
}

template<typename Type> forceinline
void hashtable_remove(HashTable<Type> table, u64 key) {
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	HashTableFindResult find_result = find(table, key);

	if (find_result.EntryIndex >= 0) {
		remove_at(table.Entries, find_result.EntryIndex);
		rehash_fast(table);
	}
}

template<typename Type> forceinline
void hashtable_remove_entry(HashTable<Type> table, ssize idx) {
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	remove_at(table.Entries, idx);
}

template<typename Type> inline
void hashtable_set(HashTable<Type>* table, u64 key, Type value)
{
	GEN_ASSERT_NOT_NULL(table);
	GEN_ASSERT_NOT_NULL(table->Hashes);
	GEN_ASSERT_NOT_NULL(table->Entries);
	ssize idx;
	HashTableFindResult find_result;

	if (hashtable_full(* table))
		hashtable_grow(table);

	find_result = hashtable__find(* table, key);
	if (find_result.EntryIndex >= 0) {
		idx = find_result.EntryIndex;
	}
	else
	{
		idx = hashtable__add_entry(table, key);

		if (find_result.PrevIndex >= 0) {
			table->Entries[find_result.PrevIndex].Next = idx;
		}
		else {
			table->Hashes[find_result.HashIndex] = idx;
		}
	}

	table->Entries[idx].Value = value;

	if (hashtable_full(* table))
		hashtable_grow(table);
}

template<typename Type> forceinline
ssize hashtable_slot(HashTable<Type> table, u64 key) {
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	for (ssize idx = 0; idx < ssize(num(table.Hashes)); ++idx)
		if (table.Hashes[idx] == key)
			return idx;

	return -1;
}

template<typename Type> forceinline
ssize hashtable__add_entry(HashTable<Type>* table, u64 key) {
	GEN_ASSERT_NOT_NULL(table);
	GEN_ASSERT_NOT_NULL(table->Hashes);
	GEN_ASSERT_NOT_NULL(table->Entries);
	ssize idx;
	HashTableEntry<Type> entry = { key, -1 };

	idx = array_num(table->Entries);
	array_append( table->Entries, entry);
	return idx;
}

template<typename Type> inline
HashTableFindResult hashtable__find(HashTable<Type> table, u64 key)
{
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	HashTableFindResult result = { -1, -1, -1 };

	if (array_num(table.Hashes) > 0)
	{
		result.HashIndex = key % array_num(table.Hashes);
		result.EntryIndex = table.Hashes[result.HashIndex];

		while (result.EntryIndex >= 0)
		{
			if (table.Entries[result.EntryIndex].Key == key)
				break;

			result.PrevIndex  = result.EntryIndex;
			result.EntryIndex = table.Entries[result.EntryIndex].Next;
		}
	}

	return result;
}

template<typename Type> forceinline
b32 hashtable_full(HashTable<Type> table) {
	GEN_ASSERT_NOT_NULL(table.Hashes);
	GEN_ASSERT_NOT_NULL(table.Entries);
	usize critical_load = usize(HashTable_CriticalLoadScale * f32(array_num(table.Hashes)));
	b32 result = array_num(table.Entries) > critical_load;
	return result;
}

#define hashtable_init(type, allocator)              hashtable_init        <type              >(allocator)
#define hashtable_init_reserve(type, allocator, num) hashtable_init_reserve<type              >(allocator, num)
#define hashtable_clear(table)                       hashtable_clear       < get_hashtable_underlying_type(table) >(table)
#define hashtable_destroy(table)                     hashtable_destroy     < get_hashtable_underlying_type(table) >(& table)
#define hashtable_get(table, key)                    hashtable_get         < get_hashtable_underlying_type(table) >(table, key)
#define hashtable_grow(table)                        hashtable_grow        < get_hashtable_underlying_type(table) >(& table)
#define hashtable_rehash(table, new_num)             hashtable_rehash      < get_hashtable_underlying_type(table) >(& table, new_num)
#define hashtable_rehash_fast(table)                 hashtable_rehash_fast < get_hashtable_underlying_type(table) >(table)
#define hashtable_remove(table, key)                 hashtable_remove      < get_hashtable_underlying_type(table) >(table, key)
#define hashtable_remove_entry(table, idx)           hashtable_remove_entry< get_hashtable_underlying_type(table) >(table, idx)
#define hashtable_set(table, key, value)             hashtable_set         < get_hashtable_underlying_type(table) >(& table, key, value)
#define hashtable_slot(table, key)                   hashtable_slot        < get_hashtable_underlying_type(table) >(table, key)
#define hashtable_map(table, map_proc)               hashtable_map         < get_hashtable_underlying_type(table) >(table, map_proc)
#define hashtable_map_mut(table, map_proc)           hashtable_map_mut     < get_hashtable_underlying_type(table) >(table, map_proc)

//#define hashtable_add_entry(table, key)              hashtable_add_entry   < get_hashtable_underlying_type(table) >(& table, key)
//#define hashtable_find(table, key)                   hashtable_find        < get_hashtable_underlying_type(table) >(table, key)
//#define hashtable_full(table)                        hashtable_full        < get_hashtable_underlying_type(table) >(table)

#pragma endregion HashTable

#pragma endregion Containers

#pragma region Hashing

GEN_API u32 crc32( void const* data, ssize len );
GEN_API u64 crc64( void const* data, ssize len );

#pragma endregion Hashing

#pragma region Strings

struct Str;

Str         to_str_from_c_str       (char const* bad_string);
bool        str_are_equal           (Str lhs, Str rhs);
char const* str_back                (Str str);
bool        str_contains            (Str str, Str substring);
Str         str_duplicate           (Str str, AllocatorInfo allocator);
b32         str_starts_with         (Str str, Str substring);
Str         str_visualize_whitespace(Str str, AllocatorInfo allocator);

// Constant string with length.
struct Str
{
	char const* Ptr;
	ssize       Len;

#if GEN_COMPILER_CPP
	forceinline operator char const* ()               const { return Ptr; }
	forceinline char const& operator[]( ssize index ) const { return Ptr[index]; }

#if ! GEN_C_LIKE_CPP
	forceinline bool        is_equal            (Str rhs)                 const { return str_are_equal(* this, rhs); }
	forceinline char const* back                ()                        const { return str_back(* this); }
	forceinline bool        contains            (Str substring)           const { return str_contains(* this, substring); }
	forceinline Str         duplicate           (AllocatorInfo allocator) const { return str_duplicate(* this, allocator); }
	forceinline b32         starts_with         (Str substring)           const { return str_starts_with(* this, substring); }
	forceinline Str         visualize_whitespace(AllocatorInfo allocator) const { return str_visualize_whitespace(* this, allocator); }
#endif
#endif
};

#define cast_to_str( str ) * rcast( Str*, (str) - sizeof(ssize) )

#ifndef txt
#	if GEN_COMPILER_CPP
#		define txt( text )          GEN_NS Str { ( text ), sizeof( text ) - 1 }
#	else
#		define txt( text )         (GEN_NS Str){ ( text ), sizeof( text ) - 1 }
#	endif
#endif

GEN_API_C_BEGIN
forceinline char const* str_begin(Str str)                   { return str.Ptr; }
forceinline char const* str_end  (Str str)                   { return str.Ptr + str.Len; }
forceinline char const* str_next (Str str, char const* iter) { return iter + 1; }
GEN_API_C_END

#if GEN_COMPILER_CPP
forceinline char const* begin(Str str)                   { return str.Ptr; }
forceinline char const* end  (Str str)                   { return str.Ptr + str.Len; }
forceinline char const* next (Str str, char const* iter) { return iter + 1; }
#endif

inline
bool str_are_equal(Str lhs, Str rhs)
{
	if (lhs.Len != rhs.Len)
		return false;

	for (ssize idx = 0; idx < lhs.Len; ++idx)
		if (lhs.Ptr[idx] != rhs.Ptr[idx])
			return false;

	return true;
}

inline
char const* str_back(Str str) {
	return & str.Ptr[str.Len - 1];
}

inline
bool str_contains(Str str, Str substring)
{
	if (substring.Len > str.Len)
		return false;

	ssize main_len = str.Len;
	ssize sub_len  = substring.Len;
	for (ssize idx = 0; idx <= main_len - sub_len; ++idx)
	{
		if (c_str_compare_len(str.Ptr + idx, substring.Ptr, sub_len) == 0)
			return true;
	}
	return false;
}

inline
b32 str_starts_with(Str str, Str substring) {
	if (substring.Len > str.Len)
		return false;

	b32 result = c_str_compare_len(str.Ptr, substring.Ptr, substring.Len) == 0;
		return result;
}

inline
Str to_str_from_c_str( char const* bad_str ) {
	Str result = { bad_str, c_str_len( bad_str ) };
	return result;
}

// Dynamic StrBuilder
// This is directly based off the ZPL string api.
// They used a header pattern
// I kept it for simplicty of porting but its not necessary to keep it that way.
#pragma region StrBuilder
struct StrBuilderHeader;

#if GEN_COMPILER_C
typedef char* StrBuilder;
#else
struct StrBuilder;
#endif

forceinline usize strbuilder_grow_formula(usize value);

GEN_API StrBuilder        strbuilder_make_reserve        (AllocatorInfo allocator, ssize        capacity);
GEN_API StrBuilder        strbuilder_make_length         (AllocatorInfo allocator, char const*  str,   ssize length);
GEN_API bool              strbuilder_make_space_for      (StrBuilder* str, char const* to_append,       ssize add_len);
GEN_API bool              strbuilder_append_c_str_len    (StrBuilder* str, char const* c_str_to_append, ssize length);
GEN_API void              strbuilder_trim                (StrBuilder  str, char const* cut_set);
GEN_API StrBuilder        strbuilder_visualize_whitespace(StrBuilder const str);

StrBuilder        strbuilder_make_c_str          (AllocatorInfo allocator, char const*  str);
StrBuilder        strbuilder_make_str            (AllocatorInfo allocator, Str         str);
StrBuilder        strbuilder_fmt                 (AllocatorInfo allocator, char*        buf,   ssize buf_size,  char const* fmt, ...);
StrBuilder        strbuilder_fmt_buf             (AllocatorInfo allocator, char const*  fmt, ...);
StrBuilder        strbuilder_join                (AllocatorInfo allocator, char const** parts, ssize num_parts, char const* glue);
bool              strbuilder_are_equal           (StrBuilder const lhs, StrBuilder const rhs);
bool              strbuilder_are_equal_str       (StrBuilder const lhs, Str rhs);
bool              strbuilder_append_char         (StrBuilder*      str, char         c);
bool              strbuilder_append_c_str        (StrBuilder*      str, char const*  c_str_to_append);
bool              strbuilder_append_str          (StrBuilder*      str, Str         c_str_to_append);
bool              strbuilder_append_string       (StrBuilder*      str, StrBuilder const other);
bool              strbuilder_append_fmt          (StrBuilder*      str, char const*  fmt, ...);
ssize             strbuilder_avail_space         (StrBuilder const str);
char*             strbuilder_back                (StrBuilder       str);
bool              strbuilder_contains_str        (StrBuilder const str, Str         substring);
bool              strbuilder_contains_string     (StrBuilder const str, StrBuilder const substring);
ssize             strbuilder_capacity            (StrBuilder const str);
void              strbuilder_clear               (StrBuilder       str);
StrBuilder        strbuilder_duplicate           (StrBuilder const str, AllocatorInfo allocator);
void              strbuilder_free                (StrBuilder*      str);
StrBuilderHeader* strbuilder_get_header          (StrBuilder       str);
ssize             strbuilder_length              (StrBuilder const str);
b32               strbuilder_starts_with_str     (StrBuilder const str, Str   substring);
b32               strbuilder_starts_with_string  (StrBuilder const str, StrBuilder substring);
void              strbuilder_skip_line           (StrBuilder       str);
void              strbuilder_strip_space         (StrBuilder       str);
Str               strbuilder_to_str              (StrBuilder       str);
void              strbuilder_trim_space          (StrBuilder       str);

struct StrBuilderHeader {
	AllocatorInfo Allocator;
	ssize         Capacity;
	ssize         Length;
};

#if GEN_COMPILER_CPP
struct StrBuilder
{
	char* Data;

	forceinline operator char*()             { return Data; }
	forceinline operator char const*() const { return Data; }
	forceinline operator Str()         const { return { Data, strbuilder_length(* this) }; }

	StrBuilder const& operator=(StrBuilder const& other) const {
		if (this == &other)
			return *this;

		StrBuilder* this_ = ccast(StrBuilder*, this);
		this_->Data = other.Data;

		return *this;
	}

	forceinline char&       operator[](ssize index)       { return Data[index]; }
	forceinline char const& operator[](ssize index) const { return Data[index]; }

	       forceinline bool operator==(std::nullptr_t) const                 { return     Data == nullptr; }
	       forceinline bool operator!=(std::nullptr_t) const                 { return     Data != nullptr; }
	friend forceinline bool operator==(std::nullptr_t, const StrBuilder str) { return str.Data == nullptr; }
	friend forceinline bool operator!=(std::nullptr_t, const StrBuilder str) { return str.Data != nullptr; }

#if ! GEN_C_LIKE_CPP
	forceinline char* begin() const { return Data; }
	forceinline char* end()   const { return Data + strbuilder_length(* this); }

#pragma region Member Mapping
	forceinline static StrBuilder make(AllocatorInfo allocator, char const* str)                { return strbuilder_make_c_str(allocator, str); }
	forceinline static StrBuilder make(AllocatorInfo allocator, Str str)                        { return strbuilder_make_str(allocator, str); }
	forceinline static StrBuilder make_reserve(AllocatorInfo allocator, ssize cap)              { return strbuilder_make_reserve(allocator, cap); }
	forceinline static StrBuilder make_length(AllocatorInfo a, char const* s, ssize l)          { return strbuilder_make_length(a, s, l); }
	forceinline static StrBuilder join(AllocatorInfo a, char const** p, ssize n, char const* g) { return strbuilder_join(a, p, n, g); }
	forceinline static usize      grow_formula(usize value)                                     { return strbuilder_grow_formula(value); }

	static
	StrBuilder fmt(AllocatorInfo allocator, char* buf, ssize buf_size, char const* fmt, ...) {
		va_list va;
		va_start(va, fmt);
		ssize res = c_str_fmt_va(buf, buf_size, fmt, va) - 1;
		va_end(va);
		return strbuilder_make_length(allocator, buf, res);
	}

	static
	StrBuilder fmt_buf(AllocatorInfo allocator, char const* fmt, ...) {
		local_persist thread_local
		char buf[GEN_PRINTF_MAXLEN] = { 0 };
		va_list va;
		va_start(va, fmt);
		ssize res = c_str_fmt_va(buf, GEN_PRINTF_MAXLEN, fmt, va) - 1;
		va_end(va);
		return strbuilder_make_length(allocator, buf, res);
	}

	forceinline bool              make_space_for(char const* str, ssize add_len) { return strbuilder_make_space_for(this, str, add_len); }
	forceinline bool              append(char c)                                 { return strbuilder_append_char(this, c); }
	forceinline bool              append(char const* str)                        { return strbuilder_append_c_str(this, str); }
	forceinline bool              append(char const* str, ssize length)          { return strbuilder_append_c_str_len(this, str, length); }
	forceinline bool              append(Str str)                                { return strbuilder_append_str(this, str); }
	forceinline bool              append(const StrBuilder other)                 { return strbuilder_append_string(this, other); }
	forceinline ssize             avail_space() const                            { return strbuilder_avail_space(* this); }
	forceinline char*             back()                                         { return strbuilder_back(* this); }
	forceinline bool              contains(Str substring) const                  { return strbuilder_contains_str(* this, substring); }
	forceinline bool              contains(StrBuilder const& substring) const    { return strbuilder_contains_string(* this, substring); }
	forceinline ssize             capacity() const                               { return strbuilder_capacity(* this); }
	forceinline void              clear()                                        {        strbuilder_clear(* this); }
	forceinline StrBuilder        duplicate(AllocatorInfo allocator) const       { return strbuilder_duplicate(* this, allocator); }
	forceinline void              free()                                         {        strbuilder_free(this); }
	forceinline bool              is_equal(StrBuilder const& other) const        { return strbuilder_are_equal(* this, other); }
	forceinline bool              is_equal(Str other) const                      { return strbuilder_are_equal_str(* this, other); }
	forceinline ssize             length() const                                 { return strbuilder_length(* this); }
	forceinline b32               starts_with(Str substring) const               { return strbuilder_starts_with_str(* this, substring); }
	forceinline b32               starts_with(StrBuilder substring) const        { return strbuilder_starts_with_string(* this, substring); }
	forceinline void              skip_line()                                    {        strbuilder_skip_line(* this); }
	forceinline void              strip_space()                                  {        strbuilder_strip_space(* this); }
	forceinline Str               to_str()                                       { return { Data, strbuilder_length(*this) }; }
	forceinline void              trim(char const* cut_set)                      {        strbuilder_trim(* this, cut_set); }
	forceinline void              trim_space()                                   {        strbuilder_trim_space(* this); }
	forceinline StrBuilder        visualize_whitespace() const                   { return strbuilder_visualize_whitespace(* this); }
	forceinline StrBuilderHeader& get_header()                                   { return * strbuilder_get_header(* this); }

	bool append_fmt(char const* fmt, ...) {
		ssize res;
		char buf[GEN_PRINTF_MAXLEN] = { 0 };

		va_list va;
		va_start(va, fmt);
		res = c_str_fmt_va(buf, count_of(buf) - 1, fmt, va) - 1;
		va_end(va);

		return strbuilder_append_c_str_len(this, buf, res);
	}
#pragma endregion Member Mapping
#endif
};
#endif

forceinline char* strbuilder_begin(StrBuilder str)                   { return ((char*) str); }
forceinline char* strbuilder_end  (StrBuilder str)                   { return ((char*) str + strbuilder_length(str)); }
forceinline char* strbuilder_next (StrBuilder str, char const* iter) { return ((char*) iter + 1); }

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
forceinline char* begin(StrBuilder str)             { return ((char*) str); }
forceinline char* end  (StrBuilder str)             { return ((char*) str + strbuilder_length(str)); }
forceinline char* next (StrBuilder str, char* iter) { return ((char*) iter + 1); }
#endif

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
forceinline bool  make_space_for(StrBuilder& str, char const* to_append, ssize add_len);
forceinline bool  append(StrBuilder& str, char c);
forceinline bool  append(StrBuilder& str, char const* c_str_to_append);
forceinline bool  append(StrBuilder& str, char const* c_str_to_append, ssize length);
forceinline bool  append(StrBuilder& str, Str c_str_to_append);
forceinline bool  append(StrBuilder& str, const StrBuilder other);
forceinline bool  append_fmt(StrBuilder& str, char const* fmt, ...);
forceinline char& back(StrBuilder& str);
forceinline void  clear(StrBuilder& str);
forceinline void  free(StrBuilder& str);
#endif

forceinline
usize strbuilder_grow_formula(usize value) {
	// Using a very aggressive growth formula to reduce time mem_copying with recursive calls to append in this library.
	return 4 * value + 8;
}

forceinline
StrBuilder strbuilder_make_c_str(AllocatorInfo allocator, char const* str) {
	ssize length = str ? c_str_len(str) : 0;
	return strbuilder_make_length(allocator, str, length);
}

forceinline
StrBuilder strbuilder_make_str(AllocatorInfo allocator, Str str) {
	return strbuilder_make_length(allocator, str.Ptr, str.Len);
}

inline
StrBuilder strbuilder_fmt(AllocatorInfo allocator, char* buf, ssize buf_size, char const* fmt, ...) {
	va_list va;
	va_start(va, fmt);
	ssize res = c_str_fmt_va(buf, buf_size, fmt, va) - 1;
	va_end(va);

	return strbuilder_make_length(allocator, buf, res);
}

inline
StrBuilder strbuilder_fmt_buf(AllocatorInfo allocator, char const* fmt, ...)
{
	local_persist thread_local
	PrintF_Buffer buf = struct_init(PrintF_Buffer, {0});

	va_list va;
	va_start(va, fmt);
	ssize res = c_str_fmt_va(buf, GEN_PRINTF_MAXLEN, fmt, va) -1;
	va_end(va);

	return strbuilder_make_length(allocator, buf, res);
}

inline
StrBuilder strbuilder_join(AllocatorInfo allocator, char const** parts, ssize num_parts, char const* glue)
{
	StrBuilder result = strbuilder_make_c_str(allocator, "");

	for (ssize idx = 0; idx < num_parts; ++idx)
	{
		strbuilder_append_c_str(& result, parts[idx]);

		if (idx < num_parts - 1)
			strbuilder_append_c_str(& result, glue);
	}

	return result;
}

forceinline
bool strbuilder_append_char(StrBuilder* str, char c) {
	GEN_ASSERT(str != nullptr);
	return strbuilder_append_c_str_len( str, (char const*)& c, (ssize)1);
}

forceinline
bool strbuilder_append_c_str(StrBuilder* str, char const* c_str_to_append) {
	GEN_ASSERT(str != nullptr);
	return strbuilder_append_c_str_len(str, c_str_to_append, c_str_len(c_str_to_append));
}

forceinline
bool strbuilder_append_str(StrBuilder* str, Str c_str_to_append) {
	GEN_ASSERT(str != nullptr);
	return strbuilder_append_c_str_len(str, c_str_to_append.Ptr, c_str_to_append.Len);
}

forceinline
bool strbuilder_append_string(StrBuilder* str, StrBuilder const other) {
	GEN_ASSERT(str != nullptr);
	return strbuilder_append_c_str_len(str, (char const*)other, strbuilder_length(other));
}

inline
bool strbuilder_append_fmt(StrBuilder* str, char const* fmt, ...) {
	GEN_ASSERT(str != nullptr);
	ssize res;
	char buf[GEN_PRINTF_MAXLEN] = { 0 };

	va_list va;
	va_start(va, fmt);
	res = c_str_fmt_va(buf, count_of(buf) - 1, fmt, va) - 1;
	va_end(va);

	return strbuilder_append_c_str_len(str, (char const*)buf, res);
}

inline
bool strbuilder_are_equal_string(StrBuilder const lhs, StrBuilder const rhs)
{
	if (strbuilder_length(lhs) != strbuilder_length(rhs))
		return false;

	for (ssize idx = 0; idx < strbuilder_length(lhs); ++idx)
		if (lhs[idx] != rhs[idx])
			return false;

	return true;
}

inline
bool strbuilder_are_equal_str(StrBuilder const lhs, Str rhs)
{
	if (strbuilder_length(lhs) != (rhs.Len))
		return false;

	for (ssize idx = 0; idx < strbuilder_length(lhs); ++idx)
		if (lhs[idx] != rhs.Ptr[idx])
			return false;

	return true;
}

forceinline
ssize strbuilder_avail_space(StrBuilder const str) {
	StrBuilderHeader const* header = rcast(StrBuilderHeader const*, scast(char const*, str) - sizeof(StrBuilderHeader));
	return header->Capacity - header->Length;
}

forceinline
char* strbuilder_back(StrBuilder str) {
	return & (str)[strbuilder_length(str) - 1];
}

inline
bool strbuilder_contains_StrC(StrBuilder const str, Str substring)
{
	StrBuilderHeader const* header = rcast(StrBuilderHeader const*, scast(char const*, str) - sizeof(StrBuilderHeader));

	if (substring.Len > header->Length)
		return false;

	ssize main_len = header->Length;
	ssize sub_len  = substring.Len;

	for (ssize idx = 0; idx <= main_len - sub_len; ++idx)
	{
		if (c_str_compare_len(str + idx, substring.Ptr, sub_len) == 0)
			return true;
	}

	return false;
}

inline
bool strbuilder_contains_string(StrBuilder const str, StrBuilder const substring)
{
	StrBuilderHeader const* header = rcast(StrBuilderHeader const*, scast(char const*, str) - sizeof(StrBuilderHeader));

	if (strbuilder_length(substring) > header->Length)
		return false;

	ssize main_len = header->Length;
	ssize sub_len  = strbuilder_length(substring);

	for (ssize idx = 0; idx <= main_len - sub_len; ++idx)
	{
		if (c_str_compare_len(str + idx, substring, sub_len) == 0)
			return true;
	}

	return false;
}

forceinline
ssize strbuilder_capacity(StrBuilder const str) {
	StrBuilderHeader const* header = rcast(StrBuilderHeader const*, scast(char const*, str) - sizeof(StrBuilderHeader));
	return header->Capacity;
}

forceinline
void strbuilder_clear(StrBuilder str) {
	strbuilder_get_header(str)->Length = 0;
}

forceinline
StrBuilder strbuilder_duplicate(StrBuilder const str, AllocatorInfo allocator) {
	return strbuilder_make_length(allocator, str, strbuilder_length(str));
}

forceinline
void strbuilder_free(StrBuilder* str) {
	GEN_ASSERT(str != nullptr);
	if (! (* str))
		return;

	StrBuilderHeader* header = strbuilder_get_header(* str);
	allocator_free(header->Allocator, header);
}

forceinline
StrBuilderHeader* strbuilder_get_header(StrBuilder str) {
	return (StrBuilderHeader*)(scast(char*, str) - sizeof(StrBuilderHeader));
}

forceinline
ssize strbuilder_length(StrBuilder const str)
{
	StrBuilderHeader const* header = rcast(StrBuilderHeader const*, scast(char const*, str) - sizeof(StrBuilderHeader));
	return header->Length;
}

forceinline
b32 strbuilder_starts_with_str(StrBuilder const str, Str substring) {
	if (substring.Len > strbuilder_length(str))
	return false;

	b32 result = c_str_compare_len(str, substring.Ptr, substring.Len) == 0;
	return result;
}

forceinline
b32 strbuilder_starts_with_string(StrBuilder const str, StrBuilder substring) {
	if (strbuilder_length(substring) > strbuilder_length(str))
		return false;

	b32 result = c_str_compare_len(str, substring, strbuilder_length(substring) - 1) == 0;
	return result;
}

inline
void strbuilder_skip_line(StrBuilder str)
{
#define current (*scanner)
	char* scanner = str;
	while (current != '\r' && current != '\n') {
		++scanner;
	}

	s32 new_length = scanner - str;

	if (current == '\r') {
		new_length += 1;
	}

	mem_move((char*)str, scanner, new_length);

	StrBuilderHeader* header = strbuilder_get_header(str);
	header->Length = new_length;
#undef current
}

inline
void strbuilder_strip_space(StrBuilder str)
{
	char* write_pos = str;
	char* read_pos  = str;

	while (* read_pos)
	{
		if (! char_is_space(* read_pos))
		{
   			* write_pos = * read_pos;
			write_pos++;
		}
		read_pos++;
	}
   write_pos[0] = '\0';  // Null-terminate the modified string

	// Update the length if needed
	strbuilder_get_header(str)->Length = write_pos - str;
}

forceinline
Str strbuilder_to_str(StrBuilder str) {
	Str result = { (char const*)str, strbuilder_length(str) };
	return result;
}

forceinline
void strbuilder_trim_space(StrBuilder str) {
	strbuilder_trim(str, " \t\r\n\v\f");
}

#pragma endregion StrBuilder

#if GEN_COMPILER_CPP
struct StrBuilder_POD {
	char* Data;
};
static_assert( sizeof( StrBuilder_POD ) == sizeof( StrBuilder ), "StrBuilder is not a POD" );
#endif

forceinline
Str str_duplicate(Str str, AllocatorInfo allocator) {
	Str result = strbuilder_to_str( strbuilder_make_length(allocator, str.Ptr, str.Len));
	return result;
}

inline
Str str_visualize_whitespace(Str str, AllocatorInfo allocator)
{
	StrBuilder result = strbuilder_make_reserve(allocator, str.Len * 2); // Assume worst case for space requirements.
	for (char const* c = str_begin(str); c != str_end(str); c = str_next(str, c))
	switch ( * c )
	{
		case ' ':
			strbuilder_append_str(& result, txt("·"));
		break;
		case '\t':
			strbuilder_append_str(& result, txt("→"));
		break;
		case '\n':
			strbuilder_append_str(& result, txt("↵"));
		break;
		case '\r':
			strbuilder_append_str(& result, txt("⏎"));
		break;
		case '\v':
			strbuilder_append_str(& result, txt("⇕"));
		break;
		case '\f':
			strbuilder_append_str(& result, txt("⌂"));
		break;
		default:
			strbuilder_append_char(& result, * c);
		break;
}
	return strbuilder_to_str(result);
}

// Represents strings cached with the string table.
// Should never be modified, if changed string is desired, cache_string( str ) another.
typedef Str StrCached;

// Implements basic string interning. Data structure is based off the ZPL Hashtable.
typedef HashTable(StrCached) StringTable;
#pragma endregion Strings

#pragma region File Handling

enum FileModeFlag
{
	EFileMode_READ   = bit( 0 ),
	EFileMode_WRITE  = bit( 1 ),
	EFileMode_APPEND = bit( 2 ),
	EFileMode_RW     = bit( 3 ),
	GEN_FILE_MODES   = EFileMode_READ | EFileMode_WRITE | EFileMode_APPEND | EFileMode_RW,
};

// NOTE: Only used internally and for the file operations
enum SeekWhenceType
{
	ESeekWhence_BEGIN   = 0,
	ESeekWhence_CURRENT = 1,
	ESeekWhence_END     = 2,
};

enum FileError
{
	EFileError_NONE,
	EFileError_INVALID,
	EFileError_INVALID_FILENAME,
	EFileError_EXISTS,
	EFileError_NOT_EXISTS,
	EFileError_PERMISSION,
	EFileError_TRUNCATION_FAILURE,
	EFileError_NOT_EMPTY,
	EFileError_NAME_TOO_LONG,
	EFileError_UNKNOWN,
};

union FileDescriptor
{
	void* p;
	sptr  i;
	uptr  u;
};

typedef u32                   FileMode;
typedef struct FileOperations FileOperations;

#define GEN_FILE_OPEN_PROC( name )     FileError name( FileDescriptor* fd, FileOperations* ops, FileMode mode, char const* filename )
#define GEN_FILE_READ_AT_PROC( name )  b32 name( FileDescriptor fd, void* buffer, ssize size, s64 offset, ssize* bytes_read, b32 stop_at_newline )
#define GEN_FILE_WRITE_AT_PROC( name ) b32 name( FileDescriptor fd, mem_ptr_const buffer, ssize size, s64 offset, ssize* bytes_written )
#define GEN_FILE_SEEK_PROC( name )     b32 name( FileDescriptor fd, s64 offset, SeekWhenceType whence, s64* new_offset )
#define GEN_FILE_CLOSE_PROC( name )    void name( FileDescriptor fd )

typedef GEN_FILE_OPEN_PROC( file_open_proc );
typedef GEN_FILE_READ_AT_PROC( FileReadProc );
typedef GEN_FILE_WRITE_AT_PROC( FileWriteProc );
typedef GEN_FILE_SEEK_PROC( FileSeekProc );
typedef GEN_FILE_CLOSE_PROC( FileCloseProc );

struct FileOperations
{
	FileReadProc*  read_at;
	FileWriteProc* write_at;
	FileSeekProc*  seek;
	FileCloseProc* close;
};

extern FileOperations const default_file_operations;

typedef u64 FileTime;

enum DirType
{
	GEN_DIR_TYPE_FILE,
	GEN_DIR_TYPE_FOLDER,
	GEN_DIR_TYPE_UNKNOWN,
};

struct DirInfo;

struct DirEntry
{
	char const* filename;
	DirInfo*    dir_info;
	u8          type;
};

struct DirInfo
{
	char const* fullpath;
	DirEntry*   entries;    // zpl_array

	// Internals
	char** filenames;    // zpl_array
	StrBuilder buf;
};

struct FileInfo
{
	FileOperations ops;
	FileDescriptor fd;
	b32            is_temp;

	char const* filename;
	FileTime    last_write_time;
	DirEntry*   dir;
};

enum FileStandardType
{
	EFileStandard_INPUT,
	EFileStandard_OUTPUT,
	EFileStandard_ERROR,

	EFileStandard_COUNT,
};

/**
	* Get standard file I/O.
	* @param  std Check zpl_file_standard_type
	* @return     File handle to standard I/O
	*/
GEN_API FileInfo* file_get_standard( FileStandardType std );

/**
	* Closes the file
	* @param  file
	*/
GEN_API FileError file_close( FileInfo* file );

/**
	* Returns the currently opened file's name
	* @param  file
	*/
inline
char const* file_name( FileInfo* file )
{
	return file->filename ? file->filename : "";
}

/**
	* Opens a file
	* @param  file
	* @param  filename
	*/
GEN_API FileError file_open( FileInfo* file, char const* filename );

/**
	* Opens a file using a specified mode
	* @param  file
	* @param  mode     Access mode to use
	* @param  filename
	*/
GEN_API FileError file_open_mode( FileInfo* file, FileMode mode, char const* filename );

/**
	* Reads from a file
	* @param  file
	* @param  buffer Buffer to read to
	* @param  size   Size to read
	*/
b32 file_read( FileInfo* file, void* buffer, ssize size );

/**
	* Reads file at a specific offset
	* @param  file
	* @param  buffer     Buffer to read to
	* @param  size       Size to read
	* @param  offset     Offset to read from
	* @param  bytes_read How much data we've actually read
	*/
b32 file_read_at( FileInfo* file, void* buffer, ssize size, s64 offset );

/**
	* Reads file safely
	* @param  file
	* @param  buffer     Buffer to read to
	* @param  size       Size to read
	* @param  offset     Offset to read from
	* @param  bytes_read How much data we've actually read
	*/
b32 file_read_at_check( FileInfo* file, void* buffer, ssize size, s64 offset, ssize* bytes_read );

typedef struct FileContents FileContents;
struct FileContents
{
	AllocatorInfo allocator;
	void*         data;
	ssize            size;
};

constexpr b32 file_zero_terminate    = true;
constexpr b32 file_no_zero_terminate = false;

/**
	* Reads the whole file contents
	* @param  a              Allocator to use
	* @param  zero_terminate End the read data with null terminator
	* @param  filepath       Path to the file
	* @return                File contents data
	*/
GEN_API FileContents file_read_contents( AllocatorInfo a, b32 zero_terminate, char const* filepath );

/**
	* Returns a size of the file
	* @param  file
	* @return      File size
	*/
GEN_API s64 file_size( FileInfo* file );

/**
	* Seeks the file cursor from the beginning of file to a specific position
	* @param  file
	* @param  offset Offset to seek to
	*/
s64 file_seek( FileInfo* file, s64 offset );

/**
	* Seeks the file cursor to the end of the file
	* @param  file
	*/
s64 file_seek_to_end( FileInfo* file );

/**
	* Returns the length from the beginning of the file we've read so far
	* @param  file
	* @return      Our current position in file
	*/
s64 file_tell( FileInfo* file );

/**
	* Writes to a file
	* @param  file
	* @param  buffer Buffer to read from
	* @param  size   Size to read
	*/
b32 file_write( FileInfo* file, void const* buffer, ssize size );

/**
	* Writes to file at a specific offset
	* @param  file
	* @param  buffer        Buffer to read from
	* @param  size          Size to write
	* @param  offset        Offset to write to
	* @param  bytes_written How much data we've actually written
	*/
b32 file_write_at( FileInfo* file, void const* buffer, ssize size, s64 offset );

/**
	* Writes to file safely
	* @param  file
	* @param  buffer        Buffer to read from
	* @param  size          Size to write
	* @param  offset        Offset to write to
	* @param  bytes_written How much data we've actually written
	*/
b32 file_write_at_check( FileInfo* file, void const* buffer, ssize size, s64 offset, ssize* bytes_written );

enum FileStreamFlags : u32
{
	/* Allows us to write to the buffer directly. Beware: you can not append a new data! */
	EFileStream_WRITABLE = bit( 0 ),

	/* Clones the input buffer so you can write (zpl_file_write*) data into it. */
	/* Since we work with a clone, the buffer size can dynamically grow as well. */
	EFileStream_CLONE_WRITABLE = bit( 1 ),

	EFileStream_UNDERLYING = GEN_U32_MAX,
};

/**
	* Opens a new memory stream
	* @param file
	* @param allocator
	*/
GEN_API b8 file_stream_new( FileInfo* file, AllocatorInfo allocator );

/**
	* Opens a memory stream over an existing buffer
	* @param  file
	* @param  allocator
	* @param  buffer   Memory to create stream from
	* @param  size     Buffer's size
	* @param  flags
	*/
GEN_API b8 file_stream_open( FileInfo* file, AllocatorInfo allocator, u8* buffer, ssize size, FileStreamFlags flags );

/**
	* Retrieves the stream's underlying buffer and buffer size.
	* @param file memory stream
	* @param size (Optional) buffer size
	*/
GEN_API u8* file_stream_buf( FileInfo* file, ssize* size );

extern FileOperations const memory_file_operations;

inline
s64 file_seek( FileInfo* f, s64 offset )
{
	s64 new_offset = 0;

	if ( ! f->ops.read_at )
		f->ops = default_file_operations;

	f->ops.seek( f->fd, offset, ESeekWhence_BEGIN, &new_offset );

	return new_offset;
}

inline
s64 file_seek_to_end( FileInfo* f )
{
	s64 new_offset = 0;

	if ( ! f->ops.read_at )
		f->ops = default_file_operations;

	f->ops.seek( f->fd, 0, ESeekWhence_END, &new_offset );

	return new_offset;
}

inline
s64 file_tell( FileInfo* f )
{
	s64 new_offset = 0;

	if ( ! f->ops.read_at )
		f->ops = default_file_operations;

	f->ops.seek( f->fd, 0, ESeekWhence_CURRENT, &new_offset );

	return new_offset;
}

inline
b32 file_read( FileInfo* f, void* buffer, ssize size )
{
	s64 cur_offset = file_tell( f );
	b32 result     = file_read_at( f, buffer, size, file_tell( f ) );
	file_seek( f, cur_offset + size );
	return result;
}

inline
b32 file_read_at( FileInfo* f, void* buffer, ssize size, s64 offset )
{
	return file_read_at_check( f, buffer, size, offset, NULL );
}

inline
b32 file_read_at_check( FileInfo* f, void* buffer, ssize size, s64 offset, ssize* bytes_read )
{
	if ( ! f->ops.read_at )
		f->ops = default_file_operations;
	return f->ops.read_at( f->fd, buffer, size, offset, bytes_read, false );
}

inline
b32 file_write( FileInfo* f, void const* buffer, ssize size )
{
	s64 cur_offset = file_tell( f );
	b32 result     = file_write_at( f, buffer, size, file_tell( f ) );

	file_seek( f, cur_offset + size );

	return result;
}

inline
b32 file_write_at( FileInfo* f, void const* buffer, ssize size, s64 offset )
{
	return file_write_at_check( f, buffer, size, offset, NULL );
}

inline
b32 file_write_at_check( FileInfo* f, void const* buffer, ssize size, s64 offset, ssize* bytes_written )
{
	if ( ! f->ops.read_at )
		f->ops = default_file_operations;

	return f->ops.write_at( f->fd, buffer, size, offset, bytes_written );
}

#pragma endregion File Handling

#pragma region Timing

#ifdef GEN_BENCHMARK
//! Return CPU timestamp.
GEN_API u64 read_cpu_time_stamp_counter( void );

//! Return relative time (in seconds) since the application start.
GEN_API f64 time_rel( void );

//! Return relative time since the application start.
GEN_API u64 time_rel_ms( void );
#endif

#pragma endregion Timing

#pragma region ADT

enum ADT_Type : u32
{
	EADT_TYPE_UNINITIALISED, /* node was not initialised, this is a programming error! */
	EADT_TYPE_ARRAY,
	EADT_TYPE_OBJECT,
	EADT_TYPE_STRING,
	EADT_TYPE_MULTISTRING,
	EADT_TYPE_INTEGER,
	EADT_TYPE_REAL,
};

enum ADT_Props : u32
{
	EADT_PROPS_NONE,
	EADT_PROPS_NAN,
	EADT_PROPS_NAN_NEG,
	EADT_PROPS_INFINITY,
	EADT_PROPS_INFINITY_NEG,
	EADT_PROPS_FALSE,
	EADT_PROPS_TRUE,
	EADT_PROPS_NULL,
	EADT_PROPS_IS_EXP,
	EADT_PROPS_IS_HEX,

	// Used internally so that people can fill in real numbers they plan to write.
	EADT_PROPS_IS_PARSED_REAL,
};

enum ADT_NamingStyle : u32
{
	EADT_NAME_STYLE_DOUBLE_QUOTE,
	EADT_NAME_STYLE_SINGLE_QUOTE,
	EADT_NAME_STYLE_NO_QUOTES,
};

enum ADT_AssignStyle : u32
{
	EADT_ASSIGN_STYLE_COLON,
	EADT_ASSIGN_STYLE_EQUALS,
	EADT_ASSIGN_STYLE_LINE,
};

enum ADT_DelimStyle : u32
{
	EADT_DELIM_STYLE_COMMA,
	EADT_DELIM_STYLE_LINE,
	EADT_DELIM_STYLE_NEWLINE,
};

enum ADT_Error : u32
{
	EADT_ERROR_NONE,
	EADT_ERROR_INTERNAL,
	EADT_ERROR_ALREADY_CONVERTED,
	EADT_ERROR_INVALID_TYPE,
	EADT_ERROR_OUT_OF_MEMORY,
};

struct ADT_Node
{
	char const*      name;
	struct ADT_Node* parent;

	/* properties */
	ADT_Type type  : 4;
	u8 props : 4;
#ifndef GEN_PARSER_DISABLE_ANALYSIS
	u8 cfg_mode          : 1;
	u8 name_style        : 2;
	u8 assign_style      : 2;
	u8 delim_style       : 2;
	u8 delim_line_width  : 4;
	u8 assign_line_width : 4;
#endif

	/* adt data */
	union
	{
		char const*     string;
		Array(ADT_Node) nodes;    ///< zpl_array

		struct
		{
			union
			{
				f64 real;
				s64 integer;
			};

#ifndef GEN_PARSER_DISABLE_ANALYSIS
			/* number analysis */
			s32 base;
			s32 base2;
			u8  base2_offset : 4;
			s8  exp          : 4;
			u8  neg_zero     : 1;
			u8  lead_digit   : 1;
#endif
		};
	};
};

/* ADT NODE LIMITS
	* delimiter and assignment segment width is limited to 128 whitespace symbols each.
	* real number limits decimal position to 128 places.
	* real number exponent is limited to 64 digits.
	*/

/**
	* @brief Initialise an ADT object or array
	*
	* @param node
	* @param backing Memory allocator used for descendants
	* @param name Node's name
	* @param is_array
	* @return error code
	*/
GEN_API u8 adt_make_branch( ADT_Node* node, AllocatorInfo backing, char const* name, b32 is_array );

/**
	* @brief Destroy an ADT branch and its descendants
	*
	* @param node
	* @return error code
	*/
GEN_API u8 adt_destroy_branch( ADT_Node* node );

/**
	* @brief Initialise an ADT leaf
	*
	* @param node
	* @param name Node's name
	* @param type Node's type (use zpl_adt_make_branch for container nodes)
	* @return error code
	*/
GEN_API u8 adt_make_leaf( ADT_Node* node, char const* name, ADT_Type type );


/**
	* @brief Fetch a node using provided URI string.
	*
	* This method uses a basic syntax to fetch a node from the ADT. The following features are available
	* to retrieve the data:
	*
	* - "a/b/c" navigates through objects "a" and "b" to get to "c"
	* - "arr/[foo=123]/bar" iterates over "arr" to find any object with param "foo" that matches the value "123", then gets its field called "bar"
	* - "arr/3" retrieves the 4th element in "arr"
	* - "arr/[apple]" retrieves the first element of value "apple" in "arr"
	*
	* @param node ADT node
	* @param uri Locator string as described above
	* @return zpl_adt_node*
	*
	* @see code/apps/examples/json_get.c
	*/
GEN_API ADT_Node* adt_query( ADT_Node* node, char const* uri );

/**
	* @brief Find a field node within an object by the given name.
	*
	* @param node
	* @param name
	* @param deep_search Perform search recursively
	* @return zpl_adt_node * node
	*/
GEN_API ADT_Node* adt_find( ADT_Node* node, char const* name, b32 deep_search );

/**
	* @brief Allocate an unitialised node within a container at a specified index.
	*
	* @param parent
	* @param index
	* @return zpl_adt_node * node
	*/
GEN_API ADT_Node* adt_alloc_at( ADT_Node* parent, ssize index );

/**
	* @brief Allocate an unitialised node within a container.
	*
	* @param parent
	* @return zpl_adt_node * node
	*/
GEN_API ADT_Node* adt_alloc( ADT_Node* parent );

/**
	* @brief Move an existing node to a new container at a specified index.
	*
	* @param node
	* @param new_parent
	* @param index
	* @return zpl_adt_node * node
	*/
GEN_API ADT_Node* adt_move_node_at( ADT_Node* node, ADT_Node* new_parent, ssize index );

/**
	* @brief Move an existing node to a new container.
	*
	* @param node
	* @param new_parent
	* @return zpl_adt_node * node
	*/
GEN_API ADT_Node* adt_move_node( ADT_Node* node, ADT_Node* new_parent );

/**
	* @brief Swap two nodes.
	*
	* @param node
	* @param other_node
	* @return
	*/
GEN_API void adt_swap_nodes( ADT_Node* node, ADT_Node* other_node );

/**
	* @brief Remove node from container.
	*
	* @param node
	* @return
	*/
GEN_API void adt_remove_node( ADT_Node* node );

/**
	* @brief Initialise a node as an object
	*
	* @param obj
	* @param name
	* @param backing
	* @return
	*/
GEN_API b8 adt_set_obj( ADT_Node* obj, char const* name, AllocatorInfo backing );

/**
	* @brief Initialise a node as an array
	*
	* @param obj
	* @param name
	* @param backing
	* @return
	*/
GEN_API b8 adt_set_arr( ADT_Node* obj, char const* name, AllocatorInfo backing );

/**
	* @brief Initialise a node as a string
	*
	* @param obj
	* @param name
	* @param value
	* @return
	*/
GEN_API b8 adt_set_str( ADT_Node* obj, char const* name, char const* value );

/**
	* @brief Initialise a node as a float
	*
	* @param obj
	* @param name
	* @param value
	* @return
	*/
GEN_API b8 adt_set_flt( ADT_Node* obj, char const* name, f64 value );

/**
	* @brief Initialise a node as a signed integer
	*
	* @param obj
	* @param name
	* @param value
	* @return
	*/
GEN_API b8 adt_set_int( ADT_Node* obj, char const* name, s64 value );

/**
	* @brief Append a new node to a container as an object
	*
	* @param parent
	* @param name
	* @return*
	*/
GEN_API ADT_Node* adt_append_obj( ADT_Node* parent, char const* name );

/**
	* @brief Append a new node to a container as an array
	*
	* @param parent
	* @param name
	* @return*
	*/
GEN_API ADT_Node* adt_append_arr( ADT_Node* parent, char const* name );

/**
	* @brief Append a new node to a container as a string
	*
	* @param parent
	* @param name
	* @param value
	* @return*
	*/
GEN_API ADT_Node* adt_append_str( ADT_Node* parent, char const* name, char const* value );

/**
	* @brief Append a new node to a container as a float
	*
	* @param parent
	* @param name
	* @param value
	* @return*
	*/
GEN_API ADT_Node* adt_append_flt( ADT_Node* parent, char const* name, f64 value );

/**
	* @brief Append a new node to a container as a signed integer
	*
	* @param parent
	* @param name
	* @param value
	* @return*
	*/
GEN_API ADT_Node* adt_append_int( ADT_Node* parent, char const* name, s64 value );

/* parser helpers */

/**
	* @brief Parses a text and stores the result into an unitialised node.
	*
	* @param node
	* @param base
	* @return*
	*/
GEN_API char* adt_parse_number( ADT_Node* node, char* base );

/**
	* @brief Parses a text and stores the result into an unitialised node.
	* This function expects the entire input to be a number.
	*
	* @param node
	* @param base
	* @return*
	*/
GEN_API char* adt_parse_number_strict( ADT_Node* node, char* base_str );

/**
	* @brief Parses and converts an existing string node into a number.
	*
	* @param node
	* @return
	*/
GEN_API ADT_Error adt_c_str_to_number( ADT_Node* node );

/**
	* @brief Parses and converts an existing string node into a number.
	* This function expects the entire input to be a number.
	*
	* @param node
	* @return
	*/
GEN_API ADT_Error adt_c_str_to_number_strict( ADT_Node* node );

/**
	* @brief Prints a number into a file stream.
	*
	* The provided file handle can also be a memory mapped stream.
	*
	* @see zpl_file_stream_new
	* @param file
	* @param node
	* @return
	*/
GEN_API ADT_Error adt_print_number( FileInfo* file, ADT_Node* node );

/**
	* @brief Prints a string into a file stream.
	*
	* The provided file handle can also be a memory mapped stream.
	*
	* @see zpl_file_stream_new
	* @param file
	* @param node
	* @param escaped_chars
	* @param escape_symbol
	* @return
	*/
GEN_API ADT_Error adt_print_string( FileInfo* file, ADT_Node* node, char const* escaped_chars, char const* escape_symbol );

#pragma endregion ADT

#pragma region CSV

enum CSV_Error : u32
{
	ECSV_Error__NONE,
	ECSV_Error__INTERNAL,
	ECSV_Error__UNEXPECTED_END_OF_INPUT,
	ECSV_Error__MISMATCHED_ROWS,
};

typedef ADT_Node CSV_Object;

        u8   csv_parse( CSV_Object* root, char* text, AllocatorInfo allocator, b32 has_header );
GEN_API u8   csv_parse_delimiter( CSV_Object* root, char* text, AllocatorInfo allocator, b32 has_header, char delim );
        void csv_free( CSV_Object* obj );

        void       csv_write( FileInfo* file, CSV_Object* obj );
        StrBuilder csv_write_string( AllocatorInfo a, CSV_Object* obj );
GEN_API void       csv_write_delimiter( FileInfo* file, CSV_Object* obj, char delim );
GEN_API StrBuilder csv_write_strbuilder_delimiter( AllocatorInfo a, CSV_Object* obj, char delim );

/* inline */

inline
u8 csv_parse( CSV_Object* root, char* text, AllocatorInfo allocator, b32 has_header )
{
	return csv_parse_delimiter( root, text, allocator, has_header, ',' );
}

inline
void csv_write( FileInfo* file, CSV_Object* obj )
{
	csv_write_delimiter( file, obj, ',' );
}

inline
StrBuilder csv_write_string( AllocatorInfo a, CSV_Object* obj )
{
	return csv_write_strbuilder_delimiter( a, obj, ',' );
}

#pragma endregion CSV

GEN_NS_END

// GEN_ROLL_OWN_DEPENDENCIES
#endif

GEN_NS_BEGIN

#pragma region Types

/*
 ________                                              __    __      ________
|        \                                            |  \  |  \    |        \
| ▓▓▓▓▓▓▓▓_______  __    __ ______ ____   _______     | ▓▓\ | ▓▓     \▓▓▓▓▓▓▓▓__    __  ______   ______   _______
| ▓▓__   |       \|  \  |  \      \    \ /       \    | ▓▓▓\| ▓▓       | ▓▓  |  \  |  \/      \ /      \ /       \
| ▓▓  \  | ▓▓▓▓▓▓▓\ ▓▓  | ▓▓ ▓▓▓▓▓▓\▓▓▓▓\  ▓▓▓▓▓▓▓    | ▓▓▓▓\ ▓▓       | ▓▓  | ▓▓  | ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\  ▓▓▓▓▓▓▓
| ▓▓▓▓▓  | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓ | ▓▓ | ▓▓\▓▓    \     | ▓▓\▓▓ ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓    ▓▓\▓▓    \
| ▓▓_____| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓ | ▓▓ | ▓▓_\▓▓▓▓▓▓\    | ▓▓ \▓▓▓▓       | ▓▓  | ▓▓__/ ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓_\▓▓▓▓▓▓\
| ▓▓     \ ▓▓  | ▓▓\▓▓    ▓▓ ▓▓ | ▓▓ | ▓▓       ▓▓    | ▓▓  \▓▓▓       | ▓▓   \▓▓    ▓▓ ▓▓    ▓▓\▓▓     \       ▓▓
 \▓▓▓▓▓▓▓▓\▓▓   \▓▓ \▓▓▓▓▓▓ \▓▓  \▓▓  \▓▓\▓▓▓▓▓▓▓      \▓▓   \▓▓        \▓▓   _\▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓\▓▓▓▓▓▓▓
                                                                             |  \__| ▓▓ ▓▓
                                                                              \▓▓    ▓▓ ▓▓
                                                                               \▓▓▓▓▓▓ \▓▓

*/

using LogFailType = ssize(*)(char const*, ...);

// By default this library will either crash or exit if an error is detected while generating codes.
// Even if set to not use GEN_FATAL, GEN_FATAL will still be used for memory failures as the library is unusable when they occur.
#ifdef GEN_DONT_USE_FATAL
	#define log_failure log_fmt
#else
	#define log_failure GEN_FATAL
#endif

enum AccessSpec : u32
{
	AccessSpec_Default,
	AccessSpec_Private,
	AccessSpec_Protected,
	AccessSpec_Public,

	AccessSpec_Num_AccessSpec,
	AccessSpec_Invalid,

	AccessSpec_SizeDef = GEN_U32_MAX,
};
static_assert( size_of(AccessSpec) == size_of(u32), "AccessSpec not u32 size" );

inline
Str access_spec_to_str( AccessSpec type )
{
	local_persist
	Str lookup[ (u32)AccessSpec_Num_AccessSpec ] = {
		{ "",        sizeof( "" )        - 1 },
		{ "private", sizeof("prviate")   - 1 },
		{ "private", sizeof("protected") - 1 },
		{ "public",  sizeof("public")    - 1 },
	};

	Str invalid = { "Invalid", sizeof("Invalid") - 1 };
	if ( type > AccessSpec_Public )
		return invalid;

	return lookup[ (u32)type ];
}

enum CodeFlag : u32
{
	CodeFlag_None          = 0,
	CodeFlag_FunctionType  = bit(0),
	CodeFlag_ParamPack     = bit(1),
	CodeFlag_Module_Export = bit(2),
	CodeFlag_Module_Import = bit(3),

	CodeFlag_SizeDef = GEN_U32_MAX,
};
static_assert( size_of(CodeFlag) == size_of(u32), "CodeFlag not u32 size" );

// Used to indicate if enum definitoin is an enum class or regular enum.
enum EnumDecl : u8
{
	EnumDecl_Regular,
	EnumDecl_Class,

	EnumT_SizeDef = GEN_U8_MAX,
};
typedef u8 EnumT;

enum ModuleFlag : u32
{
	ModuleFlag_None    = 0,
	ModuleFlag_Export  = bit(0),
	ModuleFlag_Import  = bit(1),

	Num_ModuleFlags,
	ModuleFlag_Invalid,

	ModuleFlag_SizeDef = GEN_U32_MAX,
};
static_assert( size_of(ModuleFlag) == size_of(u32), "ModuleFlag not u32 size" );

inline
Str module_flag_to_str( ModuleFlag flag )
{
	local_persist
	Str lookup[ (u32)Num_ModuleFlags ] = {
		{ "__none__", sizeof("__none__") - 1 },
		{ "export",   sizeof("export")   - 1 },
		{ "import",   sizeof("import")   - 1 },
	};

	local_persist
	Str invalid_flag = { "invalid", sizeof("invalid") };
	if ( flag > ModuleFlag_Import )
		return invalid_flag;

	return lookup[ (u32)flag ];
}

enum EPreprocessCond : u32
{
	PreprocessCond_If,
	PreprocessCond_IfDef,
	PreprocessCond_IfNotDef,
	PreprocessCond_ElIf,

	EPreprocessCond_SizeDef = GEN_U32_MAX,
};
static_assert( size_of(EPreprocessCond) == size_of(u32), "EPreprocessCond not u32 size" );

enum ETypenameTag : u16
{
	Tag_None,
	Tag_Class,
	Tag_Enum,
	Tag_Struct,
	Tag_Union,

	Tag_UnderlyingType = GEN_U16_MAX,
};
static_assert( size_of(ETypenameTag) == size_of(u16), "ETypenameTag is not u16 size");

enum CodeType : u32
{
	CT_Invalid,
	CT_Untyped,
	CT_NewLine,
	CT_Comment,
	CT_Access_Private,
	CT_Access_Protected,
	CT_Access_Public,
	CT_PlatformAttributes,
	CT_Class,
	CT_Class_Fwd,
	CT_Class_Body,
	CT_Constructor,
	CT_Constructor_Fwd,
	CT_Destructor,
	CT_Destructor_Fwd,
	CT_Enum,
	CT_Enum_Fwd,
	CT_Enum_Body,
	CT_Enum_Class,
	CT_Enum_Class_Fwd,
	CT_Execution,
	CT_Export_Body,
	CT_Extern_Linkage,
	CT_Extern_Linkage_Body,
	CT_Friend,
	CT_Function,
	CT_Function_Fwd,
	CT_Function_Body,
	CT_Global_Body,
	CT_Module,
	CT_Namespace,
	CT_Namespace_Body,
	CT_Operator,
	CT_Operator_Fwd,
	CT_Operator_Member,
	CT_Operator_Member_Fwd,
	CT_Operator_Cast,
	CT_Operator_Cast_Fwd,
	CT_Parameters,
	CT_Parameters_Define,
	CT_Preprocess_Define,
	CT_Preprocess_Include,
	CT_Preprocess_If,
	CT_Preprocess_IfDef,
	CT_Preprocess_IfNotDef,
	CT_Preprocess_ElIf,
	CT_Preprocess_Else,
	CT_Preprocess_EndIf,
	CT_Preprocess_Pragma,
	CT_Specifiers,
	CT_Struct,
	CT_Struct_Fwd,
	CT_Struct_Body,
	CT_Template,
	CT_Typedef,
	CT_Typename,
	CT_Union,
	CT_Union_Fwd,
	CT_Union_Body,
	CT_Using,
	CT_Using_Namespace,
	CT_Variable,
	CT_NumTypes,
	CT_UnderlyingType = GEN_U32_MAX
};

inline Str codetype_to_str(CodeType type)
{
	local_persist Str lookup[] = {
		{ "Invalid",             sizeof("Invalid") - 1             },
		{ "Untyped",             sizeof("Untyped") - 1             },
		{ "NewLine",             sizeof("NewLine") - 1             },
		{ "Comment",             sizeof("Comment") - 1             },
		{ "Access_Private",      sizeof("Access_Private") - 1      },
		{ "Access_Protected",    sizeof("Access_Protected") - 1    },
		{ "Access_Public",       sizeof("Access_Public") - 1       },
		{ "PlatformAttributes",  sizeof("PlatformAttributes") - 1  },
		{ "Class",               sizeof("Class") - 1               },
		{ "Class_Fwd",           sizeof("Class_Fwd") - 1           },
		{ "Class_Body",          sizeof("Class_Body") - 1          },
		{ "Constructor",         sizeof("Constructor") - 1         },
		{ "Constructor_Fwd",     sizeof("Constructor_Fwd") - 1     },
		{ "Destructor",          sizeof("Destructor") - 1          },
		{ "Destructor_Fwd",      sizeof("Destructor_Fwd") - 1      },
		{ "Enum",                sizeof("Enum") - 1                },
		{ "Enum_Fwd",            sizeof("Enum_Fwd") - 1            },
		{ "Enum_Body",           sizeof("Enum_Body") - 1           },
		{ "Enum_Class",          sizeof("Enum_Class") - 1          },
		{ "Enum_Class_Fwd",      sizeof("Enum_Class_Fwd") - 1      },
		{ "Execution",           sizeof("Execution") - 1           },
		{ "Export_Body",         sizeof("Export_Body") - 1         },
		{ "Extern_Linkage",      sizeof("Extern_Linkage") - 1      },
		{ "Extern_Linkage_Body", sizeof("Extern_Linkage_Body") - 1 },
		{ "Friend",              sizeof("Friend") - 1              },
		{ "Function",            sizeof("Function") - 1            },
		{ "Function_Fwd",        sizeof("Function_Fwd") - 1        },
		{ "Function_Body",       sizeof("Function_Body") - 1       },
		{ "Global_Body",         sizeof("Global_Body") - 1         },
		{ "Module",              sizeof("Module") - 1              },
		{ "Namespace",           sizeof("Namespace") - 1           },
		{ "Namespace_Body",      sizeof("Namespace_Body") - 1      },
		{ "Operator",            sizeof("Operator") - 1            },
		{ "Operator_Fwd",        sizeof("Operator_Fwd") - 1        },
		{ "Operator_Member",     sizeof("Operator_Member") - 1     },
		{ "Operator_Member_Fwd", sizeof("Operator_Member_Fwd") - 1 },
		{ "Operator_Cast",       sizeof("Operator_Cast") - 1       },
		{ "Operator_Cast_Fwd",   sizeof("Operator_Cast_Fwd") - 1   },
		{ "Parameters",          sizeof("Parameters") - 1          },
		{ "Parameters_Define",   sizeof("Parameters_Define") - 1   },
		{ "Preprocess_Define",   sizeof("Preprocess_Define") - 1   },
		{ "Preprocess_Include",  sizeof("Preprocess_Include") - 1  },
		{ "Preprocess_If",       sizeof("Preprocess_If") - 1       },
		{ "Preprocess_IfDef",    sizeof("Preprocess_IfDef") - 1    },
		{ "Preprocess_IfNotDef", sizeof("Preprocess_IfNotDef") - 1 },
		{ "Preprocess_ElIf",     sizeof("Preprocess_ElIf") - 1     },
		{ "Preprocess_Else",     sizeof("Preprocess_Else") - 1     },
		{ "Preprocess_EndIf",    sizeof("Preprocess_EndIf") - 1    },
		{ "Preprocess_Pragma",   sizeof("Preprocess_Pragma") - 1   },
		{ "Specifiers",          sizeof("Specifiers") - 1          },
		{ "Struct",              sizeof("Struct") - 1              },
		{ "Struct_Fwd",          sizeof("Struct_Fwd") - 1          },
		{ "Struct_Body",         sizeof("Struct_Body") - 1         },
		{ "Template",            sizeof("Template") - 1            },
		{ "Typedef",             sizeof("Typedef") - 1             },
		{ "Typename",            sizeof("Typename") - 1            },
		{ "Union",               sizeof("Union") - 1               },
		{ "Union_Fwd",           sizeof("Union_Fwd") - 1           },
		{ "Union_Body",          sizeof("Union_Body") - 1          },
		{ "Using",               sizeof("Using") - 1               },
		{ "Using_Namespace",     sizeof("Using_Namespace") - 1     },
		{ "Variable",            sizeof("Variable") - 1            },
	};
	return lookup[type];
}

inline Str codetype_to_keyword_str(CodeType type)
{
	local_persist Str lookup[] = {
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "//",              sizeof("//") - 1              },
		{ "private",         sizeof("private") - 1         },
		{ "protected",       sizeof("protected") - 1       },
		{ "public",          sizeof("public") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "class",           sizeof("class") - 1           },
		{ "clsss",           sizeof("clsss") - 1           },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "enum",            sizeof("enum") - 1            },
		{ "enum",            sizeof("enum") - 1            },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "enum class",      sizeof("enum class") - 1      },
		{ "enum class",      sizeof("enum class") - 1      },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "extern",          sizeof("extern") - 1          },
		{ "extern",          sizeof("extern") - 1          },
		{ "friend",          sizeof("friend") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "module",          sizeof("module") - 1          },
		{ "namespace",       sizeof("namespace") - 1       },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "operator",        sizeof("operator") - 1        },
		{ "operator",        sizeof("operator") - 1        },
		{ "operator",        sizeof("operator") - 1        },
		{ "operator",        sizeof("operator") - 1        },
		{ "operator",        sizeof("operator") - 1        },
		{ "operator",        sizeof("operator") - 1        },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "define",          sizeof("define") - 1          },
		{ "include",         sizeof("include") - 1         },
		{ "if",              sizeof("if") - 1              },
		{ "ifdef",           sizeof("ifdef") - 1           },
		{ "ifndef",          sizeof("ifndef") - 1          },
		{ "elif",            sizeof("elif") - 1            },
		{ "else",            sizeof("else") - 1            },
		{ "endif",           sizeof("endif") - 1           },
		{ "pragma",          sizeof("pragma") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "struct",          sizeof("struct") - 1          },
		{ "struct",          sizeof("struct") - 1          },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "template",        sizeof("template") - 1        },
		{ "typedef",         sizeof("typedef") - 1         },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "union",           sizeof("union") - 1           },
		{ "union",           sizeof("union") - 1           },
		{ "__NA__",          sizeof("__NA__") - 1          },
		{ "using",           sizeof("using") - 1           },
		{ "using namespace", sizeof("using namespace") - 1 },
		{ "__NA__",          sizeof("__NA__") - 1          },
	};
	return lookup[type];
}

forceinline Str to_str(CodeType type)
{
	return codetype_to_str(type);
}

forceinline Str to_keyword_str(CodeType type)
{
	return codetype_to_keyword_str(type);
}

enum Operator : u32
{
	Op_Invalid,
	Op_Assign,
	Op_Assign_Add,
	Op_Assign_Subtract,
	Op_Assign_Multiply,
	Op_Assign_Divide,
	Op_Assign_Modulo,
	Op_Assign_BAnd,
	Op_Assign_BOr,
	Op_Assign_BXOr,
	Op_Assign_LShift,
	Op_Assign_RShift,
	Op_Increment,
	Op_Decrement,
	Op_Unary_Plus,
	Op_Unary_Minus,
	Op_UnaryNot,
	Op_Add,
	Op_Subtract,
	Op_Multiply,
	Op_Divide,
	Op_Modulo,
	Op_BNot,
	Op_BAnd,
	Op_BOr,
	Op_BXOr,
	Op_LShift,
	Op_RShift,
	Op_LAnd,
	Op_LOr,
	Op_LEqual,
	Op_LNot,
	Op_Lesser,
	Op_Greater,
	Op_LesserEqual,
	Op_GreaterEqual,
	Op_Subscript,
	Op_Indirection,
	Op_AddressOf,
	Op_MemberOfPointer,
	Op_PtrToMemOfPtr,
	Op_FunctionCall,
	Op_Comma,
	Op_New,
	Op_NewArray,
	Op_Delete,
	Op_DeleteArray,
	Op_NumOps,
	Op_UnderlyingType = 0xffffffffu
};

inline Str operator_to_str(Operator op)
{
	local_persist Str lookup[] = {
		{ "INVALID",  sizeof("INVALID") - 1  },
		{ "=",        sizeof("=") - 1        },
		{ "+=",       sizeof("+=") - 1       },
		{ "-=",       sizeof("-=") - 1       },
		{ "*=",       sizeof("*=") - 1       },
		{ "/=",       sizeof("/=") - 1       },
		{ "%=",       sizeof("%=") - 1       },
		{ "&=",       sizeof("&=") - 1       },
		{ "|=",       sizeof("|=") - 1       },
		{ "^=",       sizeof("^=") - 1       },
		{ "<<=",      sizeof("<<=") - 1      },
		{ ">>=",      sizeof(">>=") - 1      },
		{ "++",       sizeof("++") - 1       },
		{ "--",       sizeof("--") - 1       },
		{ "+",        sizeof("+") - 1        },
		{ "-",        sizeof("-") - 1        },
		{ "!",        sizeof("!") - 1        },
		{ "+",        sizeof("+") - 1        },
		{ "-",        sizeof("-") - 1        },
		{ "*",        sizeof("*") - 1        },
		{ "/",        sizeof("/") - 1        },
		{ "%",        sizeof("%") - 1        },
		{ "~",        sizeof("~") - 1        },
		{ "&",        sizeof("&") - 1        },
		{ "|",        sizeof("|") - 1        },
		{ "^",        sizeof("^") - 1        },
		{ "<<",       sizeof("<<") - 1       },
		{ ">>",       sizeof(">>") - 1       },
		{ "&&",       sizeof("&&") - 1       },
		{ "||",       sizeof("||") - 1       },
		{ "==",       sizeof("==") - 1       },
		{ "!=",       sizeof("!=") - 1       },
		{ "<",        sizeof("<") - 1        },
		{ ">",        sizeof(">") - 1        },
		{ "<=",       sizeof("<=") - 1       },
		{ ">=",       sizeof(">=") - 1       },
		{ "[]",       sizeof("[]") - 1       },
		{ "*",        sizeof("*") - 1        },
		{ "&",        sizeof("&") - 1        },
		{ "->",       sizeof("->") - 1       },
		{ "->*",      sizeof("->*") - 1      },
		{ "()",       sizeof("()") - 1       },
		{ ",",        sizeof(",") - 1        },
		{ "new",      sizeof("new") - 1      },
		{ "new[]",    sizeof("new[]") - 1    },
		{ "delete",   sizeof("delete") - 1   },
		{ "delete[]", sizeof("delete[]") - 1 },
	};
	return lookup[op];
}

forceinline Str to_str(Operator op)
{
	return operator_to_str(op);
}

enum Specifier : u32
{
	Spec_Invalid,
	Spec_Consteval,
	Spec_Constexpr,
	Spec_Constinit,
	Spec_Explicit,
	Spec_External_Linkage,
	Spec_ForceInline,
	Spec_Global,
	Spec_Inline,
	Spec_Internal_Linkage,
	Spec_Local_Persist,
	Spec_Mutable,
	Spec_NeverInline,
	Spec_Ptr,
	Spec_Ref,
	Spec_Register,
	Spec_Restrict,
	Spec_RValue,
	Spec_Static,
	Spec_Thread_Local,
	Spec_Virtual,
	Spec_Const,
	Spec_Final,
	Spec_NoExceptions,
	Spec_Override,
	Spec_Pure,
	Spec_Delete,
	Spec_Volatile,
	Spec_NumSpecifiers,
	Spec_UnderlyingType = 0xffffffffu
};

inline Str spec_to_str(Specifier type)
{
	local_persist Str lookup[] = {
		{ "INVALID",       sizeof("INVALID") - 1       },
		{ "consteval",     sizeof("consteval") - 1     },
		{ "constexpr",     sizeof("constexpr") - 1     },
		{ "constinit",     sizeof("constinit") - 1     },
		{ "explicit",      sizeof("explicit") - 1      },
		{ "extern",        sizeof("extern") - 1        },
		{ "forceinline",   sizeof("forceinline") - 1   },
		{ "global",        sizeof("global") - 1        },
		{ "inline",        sizeof("inline") - 1        },
		{ "internal",      sizeof("internal") - 1      },
		{ "local_persist", sizeof("local_persist") - 1 },
		{ "mutable",       sizeof("mutable") - 1       },
		{ "neverinline",   sizeof("neverinline") - 1   },
		{ "*",             sizeof("*") - 1             },
		{ "&",             sizeof("&") - 1             },
		{ "register",      sizeof("register") - 1      },
		{ "restrict",      sizeof("restrict") - 1      },
		{ "&&",            sizeof("&&") - 1            },
		{ "static",        sizeof("static") - 1        },
		{ "thread_local",  sizeof("thread_local") - 1  },
		{ "virtual",       sizeof("virtual") - 1       },
		{ "const",         sizeof("const") - 1         },
		{ "final",         sizeof("final") - 1         },
		{ "noexcept",      sizeof("noexcept") - 1      },
		{ "override",      sizeof("override") - 1      },
		{ "= 0",           sizeof("= 0") - 1           },
		{ "= delete",      sizeof("= delete") - 1      },
		{ "volatile",      sizeof("volatile") - 1      },
	};
	return lookup[type];
}

inline bool spec_is_trailing(Specifier specifier)
{
	switch (specifier)
	{
		case Spec_Const:
		case Spec_Final:
		case Spec_NoExceptions:
		case Spec_Override:
		case Spec_Pure:
		case Spec_Delete:
		case Spec_Volatile:
			return true;
		default:
			return false;
	}
}

inline Specifier str_to_specifier(Str str)
{
	local_persist u32 keymap[Spec_NumSpecifiers];
	do_once_start for (u32 index = 0; index < Spec_NumSpecifiers; index++)
	{
		Str enum_str  = spec_to_str((Specifier)index);
		keymap[index] = crc32(enum_str.Ptr, enum_str.Len);
	}
	do_once_end u32 hash = crc32(str.Ptr, str.Len);
	for (u32 index = 0; index < Spec_NumSpecifiers; index++)
	{
		if (keymap[index] == hash)
			return (Specifier)index;
	}
	return Spec_Invalid;
}

forceinline Str to_str(Specifier spec)
{
	return spec_to_str(spec);
}

forceinline Specifier to_type(Str str)
{
	return str_to_specifier(str);
}

forceinline bool is_trailing(Specifier specifier)
{
	return spec_is_trailing(specifier);
}

#define GEN_DEFINE_ATTRIBUTE_TOKENS Entry(Tok_Attribute_GEN_API, "GEN_API")

enum TokType : u32
{
	Tok_Invalid,
	Tok_Access_Private,
	Tok_Access_Protected,
	Tok_Access_Public,
	Tok_Access_MemberSymbol,
	Tok_Access_StaticSymbol,
	Tok_Ampersand,
	Tok_Ampersand_DBL,
	Tok_Assign_Classifer,
	Tok_Attribute_Open,
	Tok_Attribute_Close,
	Tok_BraceCurly_Open,
	Tok_BraceCurly_Close,
	Tok_BraceSquare_Open,
	Tok_BraceSquare_Close,
	Tok_Paren_Open,
	Tok_Paren_Close,
	Tok_Comment,
	Tok_Comment_End,
	Tok_Comment_Start,
	Tok_Char,
	Tok_Comma,
	Tok_Decl_Class,
	Tok_Decl_GNU_Attribute,
	Tok_Decl_MSVC_Attribute,
	Tok_Decl_Enum,
	Tok_Decl_Extern_Linkage,
	Tok_Decl_Friend,
	Tok_Decl_Module,
	Tok_Decl_Namespace,
	Tok_Decl_Operator,
	Tok_Decl_Struct,
	Tok_Decl_Template,
	Tok_Decl_Typedef,
	Tok_Decl_Using,
	Tok_Decl_Union,
	Tok_Identifier,
	Tok_Module_Import,
	Tok_Module_Export,
	Tok_NewLine,
	Tok_Number,
	Tok_Operator,
	Tok_Preprocess_Hash,
	Tok_Preprocess_Define,
	Tok_Preprocess_Define_Param,
	Tok_Preprocess_If,
	Tok_Preprocess_IfDef,
	Tok_Preprocess_IfNotDef,
	Tok_Preprocess_ElIf,
	Tok_Preprocess_Else,
	Tok_Preprocess_EndIf,
	Tok_Preprocess_Include,
	Tok_Preprocess_Pragma,
	Tok_Preprocess_Content,
	Tok_Preprocess_Macro_Expr,
	Tok_Preprocess_Macro_Stmt,
	Tok_Preprocess_Macro_Typename,
	Tok_Preprocess_Unsupported,
	Tok_Spec_Alignas,
	Tok_Spec_Const,
	Tok_Spec_Consteval,
	Tok_Spec_Constexpr,
	Tok_Spec_Constinit,
	Tok_Spec_Explicit,
	Tok_Spec_Extern,
	Tok_Spec_Final,
	Tok_Spec_ForceInline,
	Tok_Spec_Global,
	Tok_Spec_Inline,
	Tok_Spec_Internal_Linkage,
	Tok_Spec_LocalPersist,
	Tok_Spec_Mutable,
	Tok_Spec_NeverInline,
	Tok_Spec_Override,
	Tok_Spec_Restrict,
	Tok_Spec_Static,
	Tok_Spec_ThreadLocal,
	Tok_Spec_Volatile,
	Tok_Spec_Virtual,
	Tok_Star,
	Tok_Statement_End,
	Tok_StaticAssert,
	Tok_String,
	Tok_Type_Typename,
	Tok_Type_Unsigned,
	Tok_Type_Signed,
	Tok_Type_Short,
	Tok_Type_Long,
	Tok_Type_bool,
	Tok_Type_char,
	Tok_Type_int,
	Tok_Type_double,
	Tok_Type_MS_int8,
	Tok_Type_MS_int16,
	Tok_Type_MS_int32,
	Tok_Type_MS_int64,
	Tok_Type_MS_W64,
	Tok_Varadic_Argument,
	Tok___Attributes_Start,
	Tok_Attribute_GEN_API,
	Tok_NumTokens
};

inline Str toktype_to_str(TokType type)
{
	local_persist Str lookup[] = {
		{ "__invalid__",          sizeof("__invalid__") - 1          },
		{ "private",              sizeof("private") - 1              },
		{ "protected",            sizeof("protected") - 1            },
		{ "public",               sizeof("public") - 1               },
		{ ".",		            sizeof(".") - 1                    },
		{ "::",		           sizeof("::") - 1                   },
		{ "&",		            sizeof("&") - 1                    },
		{ "&&",		           sizeof("&&") - 1                   },
		{ ":",		            sizeof(":") - 1                    },
		{ "[[",		           sizeof("[[") - 1                   },
		{ "]]",		           sizeof("]]") - 1                   },
		{ "{",		            sizeof("{") - 1                    },
		{ "}",		            sizeof("}") - 1                    },
		{ "[",		            sizeof("[") - 1                    },
		{ "]",		            sizeof("]") - 1                    },
		{ "(",		            sizeof("(") - 1                    },
		{ ")",		            sizeof(")") - 1                    },
		{ "__comment__",          sizeof("__comment__") - 1          },
		{ "__comment_end__",      sizeof("__comment_end__") - 1      },
		{ "__comment_start__",    sizeof("__comment_start__") - 1    },
		{ "__character__",        sizeof("__character__") - 1        },
		{ ",",		            sizeof(",") - 1                    },
		{ "class",                sizeof("class") - 1                },
		{ "__attribute__",        sizeof("__attribute__") - 1        },
		{ "__declspec",           sizeof("__declspec") - 1           },
		{ "enum",                 sizeof("enum") - 1                 },
		{ "extern",               sizeof("extern") - 1               },
		{ "friend",               sizeof("friend") - 1               },
		{ "module",               sizeof("module") - 1               },
		{ "namespace",            sizeof("namespace") - 1            },
		{ "operator",             sizeof("operator") - 1             },
		{ "struct",               sizeof("struct") - 1               },
		{ "template",             sizeof("template") - 1             },
		{ "typedef",              sizeof("typedef") - 1              },
		{ "using",                sizeof("using") - 1                },
		{ "union",                sizeof("union") - 1                },
		{ "__identifier__",       sizeof("__identifier__") - 1       },
		{ "import",               sizeof("import") - 1               },
		{ "export",               sizeof("export") - 1               },
		{ "__new_line__",         sizeof("__new_line__") - 1         },
		{ "__number__",           sizeof("__number__") - 1           },
		{ "__operator__",         sizeof("__operator__") - 1         },
		{ "#",		            sizeof("#") - 1                    },
		{ "define",               sizeof("define") - 1               },
		{ "__define_param__",     sizeof("__define_param__") - 1     },
		{ "if",		           sizeof("if") - 1                   },
		{ "ifdef",                sizeof("ifdef") - 1                },
		{ "ifndef",               sizeof("ifndef") - 1               },
		{ "elif",                 sizeof("elif") - 1                 },
		{ "else",                 sizeof("else") - 1                 },
		{ "endif",                sizeof("endif") - 1                },
		{ "include",              sizeof("include") - 1              },
		{ "pragma",               sizeof("pragma") - 1               },
		{ "__macro_content__",    sizeof("__macro_content__") - 1    },
		{ "__macro_expression__", sizeof("__macro_expression__") - 1 },
		{ "__macro_statment__",   sizeof("__macro_statment__") - 1   },
		{ "__macro_typename__",   sizeof("__macro_typename__") - 1   },
		{ "__unsupported__",      sizeof("__unsupported__") - 1      },
		{ "alignas",              sizeof("alignas") - 1              },
		{ "const",                sizeof("const") - 1                },
		{ "consteval",            sizeof("consteval") - 1            },
		{ "constexpr",            sizeof("constexpr") - 1            },
		{ "constinit",            sizeof("constinit") - 1            },
		{ "explicit",             sizeof("explicit") - 1             },
		{ "extern",               sizeof("extern") - 1               },
		{ "final",                sizeof("final") - 1                },
		{ "forceinline",          sizeof("forceinline") - 1          },
		{ "global",               sizeof("global") - 1               },
		{ "inline",               sizeof("inline") - 1               },
		{ "internal",             sizeof("internal") - 1             },
		{ "local_persist",        sizeof("local_persist") - 1        },
		{ "mutable",              sizeof("mutable") - 1              },
		{ "neverinline",          sizeof("neverinline") - 1          },
		{ "override",             sizeof("override") - 1             },
		{ "restrict",             sizeof("restrict") - 1             },
		{ "static",               sizeof("static") - 1               },
		{ "thread_local",         sizeof("thread_local") - 1         },
		{ "volatile",             sizeof("volatile") - 1             },
		{ "virtual",              sizeof("virtual") - 1              },
		{ "*",		            sizeof("*") - 1                    },
		{ ";",		            sizeof(";") - 1                    },
		{ "static_assert",        sizeof("static_assert") - 1        },
		{ "__string__",           sizeof("__string__") - 1           },
		{ "typename",             sizeof("typename") - 1             },
		{ "unsigned",             sizeof("unsigned") - 1             },
		{ "signed",               sizeof("signed") - 1               },
		{ "short",                sizeof("short") - 1                },
		{ "long",                 sizeof("long") - 1                 },
		{ "bool",                 sizeof("bool") - 1                 },
		{ "char",                 sizeof("char") - 1                 },
		{ "int",		          sizeof("int") - 1                  },
		{ "double",               sizeof("double") - 1               },
		{ "__int8",               sizeof("__int8") - 1               },
		{ "__int16",              sizeof("__int16") - 1              },
		{ "__int32",              sizeof("__int32") - 1              },
		{ "__int64",              sizeof("__int64") - 1              },
		{ "_W64",                 sizeof("_W64") - 1                 },
		{ "...",		          sizeof("...") - 1                  },
		{ "__attrib_start__",     sizeof("__attrib_start__") - 1     },
		{ "GEN_API",              sizeof("GEN_API") - 1              },
	};
	return lookup[type];
}

inline TokType str_to_toktype(Str str)
{
	local_persist u32 keymap[Tok_NumTokens];
	do_once_start for (u32 index = 0; index < Tok_NumTokens; index++)
	{
		Str enum_str  = toktype_to_str((TokType)index);
		keymap[index] = crc32(enum_str.Ptr, enum_str.Len);
	}
	do_once_end u32 hash = crc32(str.Ptr, str.Len);
	for (u32 index = 0; index < Tok_NumTokens; index++)
	{
		if (keymap[index] == hash)
			return (TokType)index;
	}
	return Tok_Invalid;
}

enum TokFlags : u32
{
	TF_Operator              = bit(0),
	TF_Assign                = bit(1),
	TF_Identifier            = bit(2),
	TF_Preprocess            = bit(3),
	TF_Preprocess_Cond       = bit(4),
	TF_Attribute             = bit(5),
	TF_AccessOperator        = bit(6),
	TF_AccessSpecifier       = bit(7),
	TF_Specifier             = bit(8),
	TF_EndDefinition         = bit(9),    // Either ; or }
	TF_Formatting            = bit(10),
	TF_Literal               = bit(11),
	TF_Macro_Functional      = bit(12),
	TF_Macro_Expects_Body    = bit(13),

	TF_Null = 0,
	TF_UnderlyingType = GEN_U32_MAX,
};

struct Token
{
	Str     Text;
	TokType Type;
	s32     Line;
	s32     Column;
	u32     Flags;
};

constexpr Token NullToken { {}, Tok_Invalid, 0, 0, TF_Null };

forceinline
AccessSpec tok_to_access_specifier(Token tok) {
	return scast(AccessSpec, tok.Type);
}

forceinline
bool tok_is_valid( Token tok ) {
	return tok.Text.Ptr && tok.Text.Len && tok.Type != Tok_Invalid;
}

forceinline
bool tok_is_access_operator(Token tok) {
	return bitfield_is_set( u32, tok.Flags, TF_AccessOperator );
}

forceinline
bool tok_is_access_specifier(Token tok) {
	return bitfield_is_set( u32, tok.Flags, TF_AccessSpecifier );
}

forceinline
bool tok_is_attribute(Token tok) {
	return bitfield_is_set( u32, tok.Flags, TF_Attribute );
}

forceinline
bool tok_is_operator(Token tok) {
	return bitfield_is_set( u32, tok.Flags, TF_Operator );
}

forceinline
bool tok_is_preprocessor(Token tok) {
	return bitfield_is_set( u32, tok.Flags, TF_Preprocess );
}

forceinline
bool tok_is_preprocess_cond(Token tok) {
	return bitfield_is_set( u32, tok.Flags, TF_Preprocess_Cond );
}

forceinline
bool tok_is_specifier(Token tok) {
	return bitfield_is_set( u32, tok.Flags, TF_Specifier );
}

forceinline
bool tok_is_end_definition(Token tok) {
	return bitfield_is_set( u32, tok.Flags, TF_EndDefinition );
}

StrBuilder tok_to_strbuilder(Token tok);

struct TokArray 
{
	Array(Token) Arr;
	s32          Idx;
};

struct LexContext
{
	Str             content;
	s32             left;
	char const*     scanner;
	s32             line;
	s32             column;
	// StringTable     defines;
	Token           token;
};

struct StackNode
{
	StackNode* Prev;

	Token* Start;
	Str    Name;          // The name of the AST node (if parsed)
	Str    ProcName;    // The name of the procedure
};

struct ParseContext
{
	TokArray   Tokens;
	StackNode* Scope;
};

enum MacroType : u16
{
	MT_Expression,     // A macro is assumed to be a expression if not resolved.
	MT_Statement,      
	MT_Typename,
	MT_Block_Start,    // Not Supported yet
	MT_Block_End,      // Not Supported yet
	MT_Case_Statement, // Not Supported yet

	MT_UnderlyingType = GEN_U16_MAX,
};

forceinline
TokType macrotype_to_toktype( MacroType type ) {
	switch ( type ) {
		case MT_Statement  : return Tok_Preprocess_Macro_Stmt;
		case MT_Expression : return Tok_Preprocess_Macro_Expr;
		case MT_Typename   : return Tok_Preprocess_Macro_Typename;
	}
	// All others unsupported for now.
	return Tok_Invalid;
}

inline
Str macrotype_to_str( MacroType type )
{
	local_persist
	Str lookup[] = {
		{ "Statement",        sizeof("Statement")        - 1 },
		{ "Expression",       sizeof("Expression")       - 1 },
		{ "Typename",         sizeof("Typename")         - 1 },
		{ "Block_Start",      sizeof("Block_Start")      - 1 },
		{ "Block_End",        sizeof("Block_End")        - 1 },
		{ "Case_Statement",   sizeof("Case_Statement")   - 1 },
	};
	local_persist
	Str invalid = { "Invalid", sizeof("Invalid") };
	if ( type > MT_Case_Statement )
		return invalid;

	return lookup[ type ];
}

enum EMacroFlags : u16
{
	// Macro has parameters (args expected to be passed)
	MF_Functional          = bit(0), 

	// Expects to assign a braced scope to its body.
	MF_Expects_Body        = bit(1), 

	// lex__eat wil treat this macro as an identifier if the parser attempts to consume it as one.
	// This is a kludge because we don't support push/pop macro pragmas rn.
	MF_Allow_As_Identifier = bit(2), 

	// When parsing identifiers, it will allow the consumption of the macro parameters (as its expected to be a part of constructing the identifier)
	// Example of a decarator macro from stb_sprintf.h: 
	// STBSP__PUBLICDEC int STB_SPRINTF_DECORATE(sprintf)(char* buf, char const *fmt, ...) STBSP__ATTRIBUTE_FORMAT(2,3);
	//                       ^^ STB_SPRINTF_DECORATE is decorating sprintf
	MF_Identifier_Decorator = bit(3), 

	// lex__eat wil treat this macro as an attribute if the parser attempts to consume it as one.
	// This a kludge because unreal has a macro that behaves as both a 'statement' and an attribute (UE_DEPRECATED, PRAGMA_ENABLE_DEPRECATION_WARNINGS, etc)
	// TODO(Ed): We can keep the MF_Allow_As_Attribute flag for macros, however, we need to add the ability of AST_Attributes to chain themselves.
	// Its thats already a thing in the standard language anyway
	// & it would allow UE_DEPRECATED, (UE_PROPERTY / UE_FUNCTION) to chain themselves as attributes of a resolved member function/variable definition
	MF_Allow_As_Attribute  = bit(4),

	// When a macro is encountered after attributes and specifiers while parsing a function, or variable:
	// It will consume the macro and treat it as resolving the definition.
	// (MUST BE OF MT_Statement TYPE)
	MF_Allow_As_Definition = bit(5),

	// Created for Unreal's PURE_VIRTUAL
	MF_Allow_As_Specifier = bit(6),

	MF_Null           = 0,
	MF_UnderlyingType = GEN_U16_MAX,
};
typedef u16 MacroFlags;

struct Macro
{
	StrCached  Name;
	MacroType  Type;
	MacroFlags Flags;
};

forceinline
b32 macro_is_functional( Macro macro ) {
	return bitfield_is_set( b16, macro.Flags, MF_Functional );
}

forceinline
b32 macro_expects_body( Macro macro ) {
	return bitfield_is_set( b16, macro.Flags, MF_Expects_Body );
}

#if GEN_COMPILER_CPP && ! GEN_C_LIKE_CPP
forceinline b32 is_functional( Macro macro ) { return bitfield_is_set( b16, macro.Flags, MF_Functional ); }
forceinline b32 expects_body ( Macro macro ) { return bitfield_is_set( b16, macro.Flags, MF_Expects_Body ); }
#endif

typedef HashTable(Macro) MacroTable;

#pragma endregion Types

#pragma region AST

/*
  ______   ______  ________      __    __       ______                 __
 /      \ /      \|        \    |  \  |  \     /      \               |  \
|  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓▓▓▓▓▓▓    | ▓▓\ | ▓▓    |  ▓▓▓▓▓▓\ ______   ____| ▓▓ ______
| ▓▓__| ▓▓ ▓▓___\▓▓  | ▓▓       | ▓▓▓\| ▓▓    | ▓▓   \▓▓/      \ /      ▓▓/      \
| ▓▓    ▓▓\▓▓    \   | ▓▓       | ▓▓▓▓\ ▓▓    | ▓▓     |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓▓  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓_\▓▓▓▓▓▓\  | ▓▓       | ▓▓\▓▓ ▓▓    | ▓▓   __| ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓    ▓▓
| ▓▓  | ▓▓  \__| ▓▓  | ▓▓       | ▓▓ \▓▓▓▓    | ▓▓__/  \ ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓▓▓▓▓▓▓
| ▓▓  | ▓▓\▓▓    ▓▓  | ▓▓       | ▓▓  \▓▓▓     \▓▓    ▓▓\▓▓    ▓▓\▓▓    ▓▓\▓▓     \
 \▓▓   \▓▓ \▓▓▓▓▓▓    \▓▓        \▓▓   \▓▓      \▓▓▓▓▓▓  \▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓
*/

struct AST;
struct AST_Body;
struct AST_Attributes;
struct AST_Comment;
struct AST_Constructor;
// struct AST_BaseClass;
struct AST_Class;
struct AST_Define;
struct AST_DefineParams;
struct AST_Destructor;
struct AST_Enum;
struct AST_Exec;
struct AST_Extern;
struct AST_Include;
struct AST_Friend;
struct AST_Fn;
struct AST_Module;
struct AST_NS;
struct AST_Operator;
struct AST_OpCast;
struct AST_Params;
struct AST_Pragma;
struct AST_PreprocessCond;
struct AST_Specifiers;

#ifdef GEN_EXECUTION_EXPRESSION_SUPPORT
struct AST_Expr;
struct AST_Expr_Assign;
struct AST_Expr_Alignof;
struct AST_Expr_Binary;
struct AST_Expr_CStyleCast;
struct AST_Expr_FunctionalCast;
struct AST_Expr_CppCast;
struct AST_Expr_ProcCall;
struct AST_Expr_Decltype;
struct AST_Expr_Comma;  // TODO(Ed) : This is a binary op not sure if it needs its own AST...
struct AST_Expr_AMS;    // Access Member Symbol
struct AST_Expr_Sizeof;
struct AST_Expr_Subscript;
struct AST_Expr_Ternary;
struct AST_Expr_UnaryPrefix;
struct AST_Expr_UnaryPostfix;
struct AST_Expr_Element;

struct AST_Stmt;
struct AST_Stmt_Break;
struct AST_Stmt_Case;
struct AST_Stmt_Continue;
struct AST_Stmt_Decl;
struct AST_Stmt_Do;
struct AST_Stmt_Expr;  // TODO(Ed) : Is this distinction needed? (Should it be a flag instead?)
struct AST_Stmt_Else;
struct AST_Stmt_If;
struct AST_Stmt_For;
struct AST_Stmt_Goto;
struct AST_Stmt_Label;
struct AST_Stmt_Switch;
struct AST_Stmt_While;
#endif

struct AST_Struct;
struct AST_Template;
struct AST_Typename;
struct AST_Typedef;
struct AST_Union;
struct AST_Using;
struct AST_Var;

#if GEN_COMPILER_C
typedef AST* Code;
#else
struct Code;
#endif

#if GEN_COMPILER_C
typedef AST_Body*           CodeBody;
typedef AST_Attributes*     CodeAttributes;
typedef AST_Comment*        CodeComment;
typedef AST_Class*          CodeClass;
typedef AST_Constructor*    CodeConstructor;
typedef AST_Define*         CodeDefine;
typedef AST_DefineParams*   CodeDefineParams;
typedef AST_Destructor*     CodeDestructor;
typedef AST_Enum*           CodeEnum;
typedef AST_Exec*           CodeExec;
typedef AST_Extern*         CodeExtern;
typedef AST_Include*        CodeInclude;
typedef AST_Friend*         CodeFriend;
typedef AST_Fn*             CodeFn;
typedef AST_Module*         CodeModule;
typedef AST_NS*             CodeNS;
typedef AST_Operator*       CodeOperator;
typedef AST_OpCast*         CodeOpCast;
typedef AST_Params*         CodeParams;
typedef AST_PreprocessCond* CodePreprocessCond;
typedef AST_Pragma*         CodePragma;
typedef AST_Specifiers*     CodeSpecifiers;
#else
struct CodeBody;
struct CodeAttributes;
struct CodeComment;
struct CodeClass;
struct CodeConstructor;
struct CodeDefine;
struct CodeDefineParams;
struct CodeDestructor;
struct CodeEnum;
struct CodeExec;
struct CodeExtern;
struct CodeInclude;
struct CodeFriend;
struct CodeFn;
struct CodeModule;
struct CodeNS;
struct CodeOperator;
struct CodeOpCast;
struct CodeParams;
struct CodePreprocessCond;
struct CodePragma;
struct CodeSpecifiers;
#endif

#ifdef GEN_EXECUTION_EXPRESSION_SUPPORT

#if GEN_COMPILER_C
typedef AST_Expr*                CodeExpr;
typedef AST_Expr_Assign*         CodeExpr_Assign;
typedef AST_Expr_Alignof*        CodeExpr_Alignof;
typedef AST_Expr_Binary*         CodeExpr_Binary;
typedef AST_Expr_CStyleCast*     CodeExpr_CStyleCast;
typedef AST_Expr_FunctionalCast* CodeExpr_FunctionalCast;
typedef AST_Expr_CppCast*        CodeExpr_CppCast;
typedef AST_Expr_Element*        CodeExpr_Element;
typedef AST_Expr_ProcCall*       CodeExpr_ProcCall;
typedef AST_Expr_Decltype*       CodeExpr_Decltype;
typedef AST_Expr_Comma*          CodeExpr_Comma;
typedef AST_Expr_AMS*            CodeExpr_AMS; // Access Member Symbol
typedef AST_Expr_Sizeof*         CodeExpr_Sizeof;
typedef AST_Expr_Subscript*      CodeExpr_Subscript;
typedef AST_Expr_Ternary*        CodeExpr_Ternary;
typedef AST_Expr_UnaryPrefix*    CodeExpr_UnaryPrefix;
typedef AST_Expr_UnaryPostfix*   CodeExpr_UnaryPostfix;
#else
struct CodeExpr;
struct CodeExpr_Assign;
struct CodeExpr_Alignof;
struct CodeExpr_Binary;
struct CodeExpr_CStyleCast;
struct CodeExpr_FunctionalCast;
struct CodeExpr_CppCast;
struct CodeExpr_Element;
struct CodeExpr_ProcCall;
struct CodeExpr_Decltype;
struct CodeExpr_Comma;
struct CodeExpr_AMS; // Access Member Symbol
struct CodeExpr_Sizeof;
struct CodeExpr_Subscript;
struct CodeExpr_Ternary;
struct CodeExpr_UnaryPrefix;
struct CodeExpr_UnaryPostfix;
#endif

#if GEN_COMPILER_C
typedef AST_Stmt*          CodeStmt;
typedef AST_Stmt_Break*    CodeStmt_Break;
typedef AST_Stmt_Case*     CodeStmt_Case;
typedef AST_Stmt_Continue* CodeStmt_Continue;
typedef AST_Stmt_Decl*     CodeStmt_Decl;
typedef AST_Stmt_Do*       CodeStmt_Do;
typedef AST_Stmt_Expr*     CodeStmt_Expr;
typedef AST_Stmt_Else*     CodeStmt_Else;
typedef AST_Stmt_If*       CodeStmt_If;
typedef AST_Stmt_For*      CodeStmt_For;
typedef AST_Stmt_Goto*     CodeStmt_Goto;
typedef AST_Stmt_Label*    CodeStmt_Label;
typedef AST_Stmt_Lambda*   CodeStmt_Lambda;
typedef AST_Stmt_Switch*   CodeStmt_Switch;
typedef AST_Stmt_While*    CodeStmt_While;
#else
struct CodeStmt;
struct CodeStmt_Break;
struct CodeStmt_Case;
struct CodeStmt_Continue;
struct CodeStmt_Decl;
struct CodeStmt_Do;
struct CodeStmt_Expr;
struct CodeStmt_Else;
struct CodeStmt_If;
struct CodeStmt_For;
struct CodeStmt_Goto;
struct CodeStmt_Label;
struct CodeStmt_Lambda;
struct CodeStmt_Switch;
struct CodeStmt_While;
#endif

// GEN_EXECUTION_EXPRESSION_SUPPORT
#endif

#if GEN_COMPILER_C
typedef AST_Struct*   CodeStruct;
typedef AST_Template* CodeTemplate;
typedef AST_Typename* CodeTypename;
typedef AST_Typedef*  CodeTypedef;
typedef AST_Union*    CodeUnion;
typedef AST_Using*    CodeUsing;
typedef AST_Var*      CodeVar;
#else
struct CodeStruct;
struct CodeTemplate;
struct CodeTypename;
struct CodeTypedef;
struct CodeUnion;
struct CodeUsing;
struct CodeVar;
#endif

#if GEN_COMPILER_CPP
template< class Type> forceinline Type tmpl_cast( Code self ) { return * rcast( Type*, & self ); }
#endif

#pragma region Code C-Interface

        void       code_append           (Code code, Code other );
GEN_API Str        code_debug_str        (Code code);
GEN_API Code       code_duplicate        (Code code);
        Code*      code_entry            (Code code, u32 idx );
        bool       code_has_entries      (Code code);
        bool       code_is_body          (Code code);
GEN_API bool       code_is_equal         (Code code, Code other);
        bool       code_is_valid         (Code code);
        void       code_set_global       (Code code);
GEN_API StrBuilder code_to_strbuilder    (Code self );
GEN_API void       code_to_strbuilder_ref(Code self, StrBuilder* result );
        Str        code_type_str         (Code self );
GEN_API bool       code_validate_body    (Code self );

#pragma endregion Code C-Interface

#if GEN_COMPILER_CPP
/*
	AST* wrapper
	- Not constantly have to append the '*' as this is written often..
	- Allows for implicit conversion to any of the ASTs (raw or filtered).
*/
struct Code
{
	AST* ast;

#	define Using_Code( Typename )                                                        \
	forceinline Str  debug_str()                { return code_debug_str(* this); }       \
	forceinline Code duplicate()                { return code_duplicate(* this); }	     \
	forceinline bool is_equal( Code other )     { return code_is_equal(* this, other); } \
	forceinline bool is_body()                  { return code_is_body(* this); }         \
	forceinline bool is_valid()                 { return code_is_valid(* this); }        \
	forceinline void set_global()               { return code_set_global(* this); }

#	define Using_CodeOps( Typename )                                                                           \
	forceinline Typename&  operator = ( Code other );                                                          \
	forceinline bool       operator ==( Code other )                        { return (AST*)ast == other.ast; } \
	forceinline bool       operator !=( Code other )                        { return (AST*)ast != other.ast; } \
	forceinline bool       operator ==(std::nullptr_t) const                { return ast == nullptr; }         \
	forceinline bool       operator !=(std::nullptr_t) const                { return ast != nullptr;  }        \
	operator bool();

#if ! GEN_C_LIKE_CPP
	Using_Code( Code );
	forceinline void       append(Code other)                { return code_append(* this, other); }
	forceinline Code*      entry(u32 idx)                    { return code_entry(* this, idx); }
	forceinline bool       has_entries()                     { return code_has_entries(* this); }
	forceinline StrBuilder to_strbuilder()                   { return code_to_strbuilder(* this); }
	forceinline void       to_strbuilder(StrBuilder& result) { return code_to_strbuilder_ref(* this, & result); }
	forceinline Str        type_str()                        { return code_type_str(* this); }
	forceinline bool       validate_body()                   { return code_validate_body(*this); }
#endif

	Using_CodeOps( Code );
	forceinline Code operator *() { return * this; } // Required to support for-range iteration.
	forceinline AST* operator ->() { return ast; }

	Code& operator ++();

#ifdef GEN_ENFORCE_STRONG_CODE_TYPES
#	define operator explicit operator
#endif
	operator CodeBody() const;
	operator CodeAttributes() const;
	// operator CodeBaseClass() const;
	operator CodeComment() const;
	operator CodeClass() const;
	operator CodeConstructor() const;
	operator CodeDefine() const;
	operator CodeDefineParams() const;
	operator CodeDestructor() const;
	operator CodeExec() const;
	operator CodeEnum() const;
	operator CodeExtern() const;
	operator CodeInclude() const;
	operator CodeFriend() const;
	operator CodeFn() const;
	operator CodeModule() const;
	operator CodeNS() const;
	operator CodeOperator() const;
	operator CodeOpCast() const;
	operator CodeParams() const;
	operator CodePragma() const;
	operator CodePreprocessCond() const;
	operator CodeSpecifiers() const;
	operator CodeStruct() const;
	operator CodeTemplate() const;
	operator CodeTypename() const;
	operator CodeTypedef() const;
	operator CodeUnion() const;
	operator CodeUsing() const;
	operator CodeVar() const;
	#undef operator
};
#endif

#pragma region Statics
// Used to identify ASTs that should always be duplicated. (Global constant ASTs)
GEN_API extern Code Code_Global;

// Used to identify invalid generated code.
GEN_API extern Code Code_Invalid;
#pragma endregion Statics

struct Code_POD
{
	AST* ast;
};
static_assert( sizeof(Code) == sizeof(Code_POD), "ERROR: Code is not POD" );

// Desired width of the AST data structure.
constexpr int const AST_POD_Size = 128;

constexpr static
int AST_ArrSpecs_Cap =
(
	AST_POD_Size
	- sizeof(Code)
	- sizeof(StrCached)
	- sizeof(Code) * 2
	- sizeof(Token*)
	- sizeof(Code)
	- sizeof(CodeType)
	- sizeof(ModuleFlag)
	- sizeof(u32)
)
/ sizeof(Specifier) - 1;

/*
	Simple AST POD with functionality to seralize into C++ syntax.
	TODO(Ed): Eventually haven't a transparent AST like this will longer be viable once statements & expressions are in (most likely....)
*/
struct AST
{
	union {
		struct
		{
			Code      InlineCmt;       // Class, Constructor, Destructor, Enum, Friend, Functon, Operator, OpCast, Struct, Typedef, Using, Variable
			Code      Attributes;      // Class, Enum, Function, Struct, Typedef, Union, Using, Variable // TODO(Ed): Parameters can have attributes
			Code      Specs;           // Class, Destructor, Function, Operator, Struct, Typename, Variable
			union {
				Code  InitializerList; // Constructor
				Code  ParentType;      // Class, Struct, ParentType->Next has a possible list of interfaces.
				Code  ReturnType;      // Function, Operator, Typename
				Code  UnderlyingType;  // Enum, Typedef
				Code  ValueType;       // Parameter, Variable
			};
			union {
				Code  Macro;               // Parameter
				Code  BitfieldSize;        // Variable (Class/Struct Data Member)
				Code  Params;              // Constructor, Define, Function, Operator, Template, Typename
				Code  UnderlyingTypeMacro; // Enum
			};
			union {
				Code  ArrExpr;          // Typename
				Code  Body;             // Class, Constructor, Define, Destructor, Enum, Friend, Function, Namespace, Struct, Union
				Code  Declaration;      // Friend, Template
				Code  Value;            // Parameter, Variable
			};
			union {
				Code  NextVar;          // Variable
				Code  SuffixSpecs;      // Typename, Function (Thanks Unreal)
				Code  PostNameMacro;    // Only used with parameters for specifically UE_REQUIRES (Thanks Unreal)
			};
		};
		StrCached  Content;          // Attributes, Comment, Execution, Include
		struct {
			Specifier  ArrSpecs[AST_ArrSpecs_Cap]; // Specifiers
			Code       NextSpecs;              // Specifiers; If ArrSpecs is full, then NextSpecs is used.
		};
	};
	StrCached      Name;
	union {
		Code Prev;
		Code Front;
		Code Last;
	};
	union {
		Code Next;
		Code Back;
	};
	Token*            Token; // Reference to starting token, only available if it was derived from parsing.
	Code              Parent;
	CodeType          Type;
//	CodeFlag          CodeFlags;
	ModuleFlag        ModuleFlags;
	union {
		b32           IsFunction;  // Used by typedef to not serialize the name field.
		struct {
			b16           IsParamPack;   // Used by typename to know if type should be considered a parameter pack.
			ETypenameTag  TypeTag;       // Used by typename to keep track of explicitly declared tags for the identifier (enum, struct, union)
		};
		Operator      Op;
		AccessSpec    ParentAccess;
		s32           NumEntries;
		s32           VarParenthesizedInit;  // Used by variables to know that initialization is using a constructor expression instead of an assignment expression.
	};
};
static_assert( sizeof(AST) == AST_POD_Size, "ERROR: AST is not size of AST_POD_Size" );

#if GEN_COMPILER_CPP
// Uses an implicitly overloaded cast from the AST to the desired code type.
// Necessary if the user wants GEN_ENFORCE_STRONG_CODE_TYPES
struct  InvalidCode_ImplictCaster;
#define InvalidCode (InvalidCode_ImplictCaster{})
#else
#define InvalidCode (void*){ (void*)Code_Invalid }
#endif

#if GEN_COMPILER_CPP
struct NullCode_ImplicitCaster;
// Used when the its desired when omission is allowed in a definition.
#define NullCode    (NullCode_ImplicitCaster{})
#else
#define NullCode    nullptr
#endif

/*
  ______                 __               ______            __                        ______
 /      \               |  \             |      \          |  \                      /      \
|  ▓▓▓▓▓▓\ ______   ____| ▓▓ ______       \▓▓▓▓▓▓_______  _| ▓▓_    ______   ______ |  ▓▓▓▓▓▓\ ______   _______  ______
| ▓▓   \▓▓/      \ /      ▓▓/      \       | ▓▓ |       \|   ▓▓ \  /      \ /      \| ▓▓_  \▓▓|      \ /       \/      \
| ▓▓     |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓▓  ▓▓▓▓▓▓\      | ▓▓ | ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓ \     \▓▓▓▓▓▓\  ▓▓▓▓▓▓▓  ▓▓▓▓▓▓\
| ▓▓   __| ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓    ▓▓      | ▓▓ | ▓▓  | ▓▓ | ▓▓ __| ▓▓    ▓▓ ▓▓   \▓▓ ▓▓▓▓    /      ▓▓ ▓▓     | ▓▓    ▓▓
| ▓▓__/  \ ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓▓▓▓▓▓▓     _| ▓▓_| ▓▓  | ▓▓ | ▓▓|  \ ▓▓▓▓▓▓▓▓ ▓▓     | ▓▓     |  ▓▓▓▓▓▓▓ ▓▓_____| ▓▓▓▓▓▓▓▓
 \▓▓    ▓▓\▓▓    ▓▓\▓▓    ▓▓\▓▓     \    |   ▓▓ \ ▓▓  | ▓▓  \▓▓  ▓▓\▓▓     \ ▓▓     | ▓▓      \▓▓    ▓▓\▓▓     \\▓▓     \
  \▓▓▓▓▓▓  \▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓     \▓▓▓▓▓▓\▓▓   \▓▓   \▓▓▓▓  \▓▓▓▓▓▓▓\▓▓      \▓▓       \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓
*/

#pragma region Code Type C-Interface

GEN_API void       body_append              ( CodeBody body, Code     other );
GEN_API void       body_append_body         ( CodeBody body, CodeBody other );
GEN_API StrBuilder body_to_strbuilder       ( CodeBody body );
        void       body_to_strbuilder_ref   ( CodeBody body, StrBuilder* result );
GEN_API void       body_to_strbuilder_export( CodeBody body, StrBuilder* result );

Code begin_CodeBody( CodeBody body);
Code end_CodeBody  ( CodeBody body );
Code next_CodeBody ( CodeBody body, Code entry_iter );

        void       class_add_interface    ( CodeClass self, CodeTypename interface );
GEN_API StrBuilder class_to_strbuilder    ( CodeClass self );
GEN_API void       class_to_strbuilder_def( CodeClass self, StrBuilder* result );
GEN_API void       class_to_strbuilder_fwd( CodeClass self, StrBuilder* result );

        void             define_params_append           (CodeDefineParams appendee, CodeDefineParams other );
        CodeDefineParams define_params_get              (CodeDefineParams params, s32 idx);
        bool             define_params_has_entries      (CodeDefineParams params );
        StrBuilder       define_params_to_strbuilder    (CodeDefineParams params );
GEN_API void             define_params_to_strbuilder_ref(CodeDefineParams params, StrBuilder* result );

CodeDefineParams begin_CodeDefineParams(CodeDefineParams params);
CodeDefineParams end_CodeDefineParams  (CodeDefineParams params);
CodeDefineParams next_CodeDefineParams (CodeDefineParams params, CodeDefineParams entry_iter);

        void       params_append           (CodeParams appendee, CodeParams other );
        CodeParams params_get              (CodeParams params, s32 idx);
        bool       params_has_entries      (CodeParams params );
        StrBuilder params_to_strbuilder    (CodeParams params );
GEN_API void       params_to_strbuilder_ref(CodeParams params, StrBuilder* result );

CodeParams begin_CodeParams(CodeParams params);
CodeParams end_CodeParams  (CodeParams params);
CodeParams next_CodeParams (CodeParams params, CodeParams entry_iter);

        bool       specifiers_append           (CodeSpecifiers specifiers, Specifier spec);
        bool       specifiers_has              (CodeSpecifiers specifiers, Specifier spec);
        s32        specifiers_index_of         (CodeSpecifiers specifiers, Specifier spec);
        s32        specifiers_remove           (CodeSpecifiers specifiers, Specifier to_remove );
        StrBuilder specifiers_to_strbuilder    (CodeSpecifiers specifiers);
GEN_API void       specifiers_to_strbuilder_ref(CodeSpecifiers specifiers, StrBuilder* result);

Specifier* begin_CodeSpecifiers(CodeSpecifiers specifiers);
Specifier* end_CodeSpecifiers  (CodeSpecifiers specifiers);
Specifier* next_CodeSpecifiers (CodeSpecifiers specifiers, Specifier* spec_iter);

        void       struct_add_interface    (CodeStruct self, CodeTypename interface);
GEN_API StrBuilder struct_to_strbuilder    (CodeStruct self);
GEN_API void       struct_to_strbuilder_fwd(CodeStruct self, StrBuilder* result);
GEN_API void       struct_to_strbuilder_def(CodeStruct self, StrBuilder* result);

        StrBuilder attributes_to_strbuilder    (CodeAttributes attributes);
        void       attributes_to_strbuilder_ref(CodeAttributes attributes, StrBuilder* result);

        StrBuilder comment_to_strbuilder    (CodeComment comment );
        void       comment_to_strbuilder_ref(CodeComment comment, StrBuilder* result );

GEN_API StrBuilder constructor_to_strbuilder    (CodeConstructor constructor);
GEN_API void       constructor_to_strbuilder_def(CodeConstructor constructor, StrBuilder* result );
GEN_API void       constructor_to_strbuilder_fwd(CodeConstructor constructor, StrBuilder* result );

GEN_API StrBuilder define_to_strbuilder    (CodeDefine self);
GEN_API void       define_to_strbuilder_ref(CodeDefine self, StrBuilder* result);

GEN_API StrBuilder destructor_to_strbuilder    (CodeDestructor destructor);
GEN_API void       destructor_to_strbuilder_fwd(CodeDestructor destructor, StrBuilder* result );
GEN_API void       destructor_to_strbuilder_def(CodeDestructor destructor, StrBuilder* result );

GEN_API StrBuilder enum_to_strbuilder          (CodeEnum self);
GEN_API void       enum_to_strbuilder_def      (CodeEnum self, StrBuilder* result );
GEN_API void       enum_to_strbuilder_fwd      (CodeEnum self, StrBuilder* result );
GEN_API void       enum_to_strbuilder_class_def(CodeEnum self, StrBuilder* result );
GEN_API void       enum_to_strbuilder_class_fwd(CodeEnum self, StrBuilder* result );

        StrBuilder exec_to_strbuilder    (CodeExec exec);
        void       exec_to_strbuilder_ref(CodeExec exec, StrBuilder* result);

        void extern_to_strbuilder(CodeExtern self, StrBuilder* result);

        StrBuilder include_to_strbuilder    (CodeInclude self);
        void       include_to_strbuilder_ref(CodeInclude self, StrBuilder* result);

        StrBuilder friend_to_strbuilder     (CodeFriend self);
        void       friend_to_strbuilder_ref(CodeFriend self, StrBuilder* result);

GEN_API StrBuilder fn_to_strbuilder    (CodeFn self);
GEN_API void       fn_to_strbuilder_def(CodeFn self, StrBuilder* result);
GEN_API void       fn_to_strbuilder_fwd(CodeFn self, StrBuilder* result);

        StrBuilder module_to_strbuilder    (CodeModule self);
GEN_API void       module_to_strbuilder_ref(CodeModule self, StrBuilder* result);

        StrBuilder namespace_to_strbuilder    (CodeNS self);
        void       namespace_to_strbuilder_ref(CodeNS self, StrBuilder* result);

GEN_API StrBuilder code_op_to_strbuilder    (CodeOperator self);
GEN_API void       code_op_to_strbuilder_fwd(CodeOperator self, StrBuilder* result );
GEN_API void       code_op_to_strbuilder_def(CodeOperator self, StrBuilder* result );

GEN_API StrBuilder opcast_to_strbuilder    (CodeOpCast op_cast );
GEN_API void       opcast_to_strbuilder_def(CodeOpCast op_cast, StrBuilder* result );
GEN_API void       opcast_to_strbuilder_fwd(CodeOpCast op_cast, StrBuilder* result );

        StrBuilder pragma_to_strbuilder    (CodePragma self);
        void       pragma_to_strbuilder_ref(CodePragma self, StrBuilder* result);

GEN_API StrBuilder preprocess_to_strbuilder       (CodePreprocessCond cond);
        void       preprocess_to_strbuilder_if    (CodePreprocessCond cond, StrBuilder* result );
        void       preprocess_to_strbuilder_ifdef (CodePreprocessCond cond, StrBuilder* result );
        void       preprocess_to_strbuilder_ifndef(CodePreprocessCond cond, StrBuilder* result );
        void       preprocess_to_strbuilder_elif  (CodePreprocessCond cond, StrBuilder* result );
        void       preprocess_to_strbuilder_else  (CodePreprocessCond cond, StrBuilder* result );
        void       preprocess_to_strbuilder_endif (CodePreprocessCond cond, StrBuilder* result );

        StrBuilder template_to_strbuilder    (CodeTemplate self);
GEN_API void       template_to_strbuilder_ref(CodeTemplate self, StrBuilder* result);

        StrBuilder typedef_to_strbuilder    (CodeTypedef self);
GEN_API void       typedef_to_strbuilder_ref(CodeTypedef self, StrBuilder* result );

        StrBuilder typename_to_strbuilder    (CodeTypename self);
GEN_API void       typename_to_strbuilder_ref(CodeTypename self, StrBuilder* result);

GEN_API StrBuilder union_to_strbuilder    (CodeUnion self);
GEN_API void       union_to_strbuilder_def(CodeUnion self, StrBuilder* result);
GEN_API void       union_to_strbuilder_fwd(CodeUnion self, StrBuilder* result);

        StrBuilder using_to_strbuilder    (CodeUsing op_cast );
GEN_API void       using_to_strbuilder_ref(CodeUsing op_cast, StrBuilder* result );
        void       using_to_strbuilder_ns (CodeUsing op_cast, StrBuilder* result );

        StrBuilder var_to_strbuilder    (CodeVar self);
GEN_API void       var_to_strbuilder_ref(CodeVar self, StrBuilder* result);

// TODO(Ed): Move C-Interface inlines here...

#pragma endregion Code Type C-Interface

#if GEN_COMPILER_CPP
#pragma region Code Types C++

// These structs are not used at all by the C vairant.
static_assert( GEN_COMPILER_CPP, "This should not be compiled with the C-library" );

#define Verify_POD(Type) static_assert(size_of(Code##Type) == size_of(AST_##Type), "ERROR: Code##Type is not a POD")

struct CodeBody
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeBody );
	forceinline void       append( Code other )                       { return body_append( *this, other ); }
	forceinline void       append( CodeBody body )                    { return body_append(*this, body); }
	forceinline bool       has_entries()                              { return code_has_entries(* this); }
	forceinline StrBuilder to_strbuilder()                            { return body_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result )        { return body_to_strbuilder_ref(* this, & result ); }
	forceinline void       to_strbuilder_export( StrBuilder& result ) { return body_to_strbuilder_export(* this, & result); }

#endif
	forceinline Code begin() { return begin_CodeBody(* this); }
	forceinline Code end()   { return end_CodeBody(* this); }
	Using_CodeOps( CodeBody );
	forceinline operator Code() { return * rcast( Code*, this ); }
	forceinline AST_Body* operator->() { return ast; }
	AST_Body* ast;
};

struct CodeClass
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeClass );
	forceinline void       add_interface( CodeType interface );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder_def( StrBuilder& result );
	forceinline void       to_strbuilder_fwd( StrBuilder& result );
#endif
	Using_CodeOps( CodeClass );
	forceinline operator Code() { return * rcast( Code*, this ); }
	forceinline AST_Class* operator->() {
		GEN_ASSERT(ast);
		return ast;
	}
	AST_Class* ast;
};

struct CodeParams
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeParams );
	forceinline void          append( CodeParams other )          { return params_append(* this, other); }
	forceinline CodeParams    get( s32 idx )                      { return params_get( * this, idx); }
	forceinline bool          has_entries()                       { return params_has_entries(* this); }
	forceinline StrBuilder    to_strbuilder()                     { return params_to_strbuilder(* this); }
	forceinline void          to_strbuilder( StrBuilder& result ) { return params_to_strbuilder_ref(*this, & result); }
#endif
	Using_CodeOps( CodeParams );
	forceinline CodeParams begin() { return begin_CodeParams(* this); }
	forceinline CodeParams end()   { return end_CodeParams(* this); }
	forceinline operator Code() { return { (AST*)ast }; }
	forceinline CodeParams  operator *() { return * this; } // Required to support for-range iteration.
	forceinline AST_Params* operator->() {
		GEN_ASSERT(ast);
		return ast;
	}
	CodeParams& operator++();
	AST_Params* ast;
};

struct CodeDefineParams
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeDefineParams );
	forceinline void             append( CodeDefineParams other )    { return params_append( cast(CodeParams, * this), cast(CodeParams, other)); }
	forceinline CodeDefineParams get( s32 idx )                      { return (CodeDefineParams) (Code) params_get( cast(CodeParams, * this), idx); }
	forceinline bool             has_entries()                       { return params_has_entries( cast(CodeParams, * this)); }
	forceinline StrBuilder       to_strbuilder()                     { return define_params_to_strbuilder(* this); }
	forceinline void             to_strbuilder( StrBuilder& result ) { return define_params_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps( CodeDefineParams );
	forceinline CodeDefineParams begin() { return (CodeDefineParams) (Code) begin_CodeParams( cast(CodeParams, * this)); }
	forceinline CodeDefineParams end()   { return (CodeDefineParams) (Code) end_CodeParams( cast(CodeParams, * this)); }
	forceinline operator Code() { return { (AST*)ast }; }
	forceinline CodeDefineParams  operator *() { return * this; } // Required to support for-range iteration.
	forceinline AST_DefineParams* operator->() {
		GEN_ASSERT(ast);
		return ast;
	}
	forceinline CodeDefineParams& operator++();
	AST_DefineParams* ast;
};

struct CodeSpecifiers
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeSpecifiers );
	bool       append( Specifier spec )            { return specifiers_append(* this, spec); }
	s32        has( Specifier spec )               { return specifiers_has(* this, spec); }
	s32        remove( Specifier to_remove )       { return specifiers_remove(* this, to_remove); }
	StrBuilder to_strbuilder()                     { return specifiers_to_strbuilder(* this ); }
	void       to_strbuilder( StrBuilder& result ) { return specifiers_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeSpecifiers);
	forceinline operator Code() { return { (AST*) ast }; }
	forceinline Code            operator *() { return * this; } // Required to support for-range iteration.
	forceinline AST_Specifiers* operator->() {
		GEN_ASSERT(ast);
		return ast;
	}
	AST_Specifiers* ast;
};

struct CodeAttributes
{
#if ! GEN_C_LIKE_CPP
	Using_Code(CodeAttributes);
	forceinline StrBuilder to_strbuilder()                   { return attributes_to_strbuilder(* this); }
	forceinline void       to_strbuilder(StrBuilder& result) { return attributes_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeAttributes);
	operator Code();
	AST_Attributes *operator->();
	AST_Attributes *ast;
};

// Define_CodeType( BaseClass );

struct CodeComment
{
#if ! GEN_C_LIKE_CPP
	Using_Code(CodeComment);
	forceinline StrBuilder to_strbuilder()                   { return comment_to_strbuilder    (* this); }
	forceinline void       to_strbuilder(StrBuilder& result) { return comment_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeComment);
	operator Code();
	AST_Comment *operator->();
	AST_Comment *ast;
};

struct CodeConstructor
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeConstructor );
	forceinline StrBuilder to_strbuilder()                         { return constructor_to_strbuilder(* this); }
	forceinline void       to_strbuilder_def( StrBuilder& result ) { return constructor_to_strbuilder_def(* this, & result); }
	forceinline void       to_strbuilder_fwd( StrBuilder& result ) { return constructor_to_strbuilder_fwd(* this, & result); }
#endif
	Using_CodeOps(CodeConstructor);
	operator         Code();
	AST_Constructor* operator->();
	AST_Constructor* ast;
};

struct CodeDefine
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeDefine );
	forceinline StrBuilder to_strbuilder()                     { return define_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return define_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeDefine);
	operator    Code();
	AST_Define* operator->();
	AST_Define* ast;
};

struct CodeDestructor
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeDestructor );
	forceinline StrBuilder to_strbuilder()                         { return destructor_to_strbuilder(* this); }
	forceinline void       to_strbuilder_def( StrBuilder& result ) { return destructor_to_strbuilder_def(* this, & result); }
	forceinline void       to_strbuilder_fwd( StrBuilder& result ) { return destructor_to_strbuilder_fwd(* this, & result); }
#endif
	Using_CodeOps(CodeDestructor);
	operator         Code();
	AST_Destructor* operator->();
	AST_Destructor* ast;
};

struct CodeEnum
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeEnum );
	forceinline StrBuilder to_strbuilder()                                { return enum_to_strbuilder(* this); }
	forceinline void       to_strbuilder_def( StrBuilder& result )        { return enum_to_strbuilder_def(* this, & result); }
	forceinline void       to_strbuilder_fwd( StrBuilder& result )        { return enum_to_strbuilder_fwd(* this, & result); }
	forceinline void       to_strbuilder_class_def( StrBuilder& result )  { return enum_to_strbuilder_class_def(* this, & result); }
	forceinline void       to_strbuilder_class_fwd( StrBuilder& result )  { return enum_to_strbuilder_class_fwd(* this, & result); }
#endif
	Using_CodeOps(CodeEnum);
	operator  Code();
	AST_Enum* operator->();
	AST_Enum* ast;
};

struct CodeExec
{
#if ! GEN_C_LIKE_CPP
	Using_Code(CodeExec);
	forceinline StrBuilder to_strbuilder()               { return exec_to_strbuilder(* this); }
	forceinline void   to_strbuilder(StrBuilder& result) { return exec_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeExec);
	operator Code();
	AST_Exec *operator->();
	AST_Exec *ast;
};

#ifdef GEN_EXECUTION_EXPRESSION_SUPPORT
struct CodeExpr
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator  Code();
	AST_Expr* operator->();
	AST_Expr* ast;
};

struct CodeExpr_Assign
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Assign );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator         Code();
	AST_Expr_Assign* operator->();
	AST_Expr_Assign* ast;
};

struct CodeExpr_Alignof
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Alignof );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator          Code();
	AST_Expr_Alignof* operator->();
	AST_Expr_Alignof* ast;
};

struct CodeExpr_Binary
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Binary );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator         Code();
	AST_Expr_Binary* operator->();
	AST_Expr_Binary* ast;
};

struct CodeExpr_CStyleCast
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_CStyleCast );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator             Code();
	AST_Expr_CStyleCast* operator->();
	AST_Expr_CStyleCast* ast;
};

struct CodeExpr_FunctionalCast
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_FunctionalCast );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator                 Code();
	AST_Expr_FunctionalCast* operator->();
	AST_Expr_FunctionalCast* ast;
};

struct CodeExpr_CppCast
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_CppCast );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator          Code();
	AST_Expr_CppCast* operator->();
	AST_Expr_CppCast* ast;
};

struct CodeExpr_Element
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Element );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator          Code();
	AST_Expr_Element* operator->();
	AST_Expr_Element* ast;
};

struct CodeExpr_ProcCall
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_ProcCall );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator           Code();
	AST_Expr_ProcCall* operator->();
	AST_Expr_ProcCall* ast;
};

struct CodeExpr_Decltype
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Decltype );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator  Code();
	AST_Expr_Decltype* operator->();
	AST_Expr_Decltype* ast;
};

struct CodeExpr_Comma
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Comma );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator  Code();
	AST_Expr_Comma* operator->();
	AST_Expr_Comma* ast;
};

struct CodeExpr_AMS
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_AMS );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator      Code();
	AST_Expr_AMS* operator->();
	AST_Expr_AMS* ast;
};

struct CodeExpr_Sizeof
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Sizeof );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator         Code();
	AST_Expr_Sizeof* operator->();
	AST_Expr_Sizeof* ast;
};

struct CodeExpr_Subscript
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Subscript );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator            Code();
	AST_Expr_Subscript* operator->();
	AST_Expr_Subscript* ast;
};

struct CodeExpr_Ternary
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_Ternary );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator          Code();
	AST_Expr_Ternary* operator->();
	AST_Expr_Ternary* ast;
};

struct CodeExpr_UnaryPrefix
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_UnaryPrefix );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	operator              Code();
	AST_Expr_UnaryPrefix* operator->();
	AST_Expr_UnaryPrefix* ast;
};

struct CodeExpr_UnaryPostfix
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExpr_UnaryPostfix );
	forceinline void to_strbuilder( StrBuilder& result );
#endif
	AST*                   raw();
	operator               Code();
	AST_Expr_UnaryPostfix* operator->();
	AST_Expr_UnaryPostfix* ast;
};
#endif

struct CodeExtern
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeExtern );
	forceinline void to_strbuilder( StrBuilder& result ) { return extern_to_strbuilder(* this, & result); }
#endif
	Using_CodeOps(CodeExtern);
	operator    Code();
	AST_Extern* operator->();
	AST_Extern* ast;
};

struct CodeInclude
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeInclude );
	forceinline StrBuilder to_strbuilder()                      { return include_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result )  { return include_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeInclude);
	operator     Code();
	AST_Include* operator->();
	AST_Include* ast;
};

struct CodeFriend
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeFriend );
	forceinline StrBuilder to_strbuilder()                     { return friend_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return friend_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeFriend);
	operator    Code();
	AST_Friend* operator->();
	AST_Friend* ast;
};

struct CodeFn
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeFn );
	forceinline StrBuilder to_strbuilder()                         { return fn_to_strbuilder(* this); }
	forceinline void       to_strbuilder_def( StrBuilder& result ) { return fn_to_strbuilder_def(* this, & result); }
	forceinline void       to_strbuilder_fwd( StrBuilder& result ) { return fn_to_strbuilder_fwd(* this, & result); }
#endif
	Using_CodeOps(CodeFn);
	operator Code();
	AST_Fn*  operator->();
	AST_Fn*  ast;
};

struct CodeModule
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeModule );
	forceinline StrBuilder to_strbuilder()                     { return module_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return module_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeModule);
	operator    Code();
	AST_Module* operator->();
	AST_Module* ast;
};

struct CodeNS
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeNS );
	forceinline StrBuilder to_strbuilder()                     { return namespace_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return namespace_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeNS);
	operator Code();
	AST_NS*  operator->();
	AST_NS*  ast;
};

struct CodeOperator
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeOperator );
	forceinline StrBuilder to_strbuilder()                         { return code_op_to_strbuilder(* this); }
	forceinline void       to_strbuilder_def( StrBuilder& result ) { return code_op_to_strbuilder_def(* this, & result); }
	forceinline void       to_strbuilder_fwd( StrBuilder& result ) { return code_op_to_strbuilder_fwd(* this, & result); }
#endif
	Using_CodeOps(CodeOperator);
	operator      Code();
	AST_Operator* operator->();
	AST_Operator* ast;
};

struct CodeOpCast
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeOpCast );
	forceinline StrBuilder to_strbuilder()                         { return opcast_to_strbuilder(* this); }
	forceinline void       to_strbuilder_def( StrBuilder& result ) { return opcast_to_strbuilder_def(* this, & result); }
	forceinline void       to_strbuilder_fwd( StrBuilder& result ) { return opcast_to_strbuilder_fwd(* this, & result); }
#endif
	Using_CodeOps(CodeOpCast);
	operator    Code();
	AST_OpCast* operator->();
	AST_OpCast* ast;
};

struct CodePragma
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodePragma );
	forceinline StrBuilder to_strbuilder()                     { return pragma_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return pragma_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps( CodePragma );
	operator    Code();
	AST_Pragma* operator->();
	AST_Pragma* ast;
};

struct CodePreprocessCond
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodePreprocessCond );
	forceinline StrBuilder to_strbuilder()                            { return preprocess_to_strbuilder(* this); }
	forceinline void       to_strbuilder_if( StrBuilder& result )     { return preprocess_to_strbuilder_if(* this, & result); }
	forceinline void       to_strbuilder_ifdef( StrBuilder& result )  { return preprocess_to_strbuilder_ifdef(* this, & result); }
	forceinline void       to_strbuilder_ifndef( StrBuilder& result ) { return preprocess_to_strbuilder_ifndef(* this, & result); }
	forceinline void       to_strbuilder_elif( StrBuilder& result )   { return preprocess_to_strbuilder_elif(* this, & result); }
	forceinline void       to_strbuilder_else( StrBuilder& result )   { return preprocess_to_strbuilder_else(* this, & result); }
	forceinline void       to_strbuilder_endif( StrBuilder& result )  { return preprocess_to_strbuilder_endif(* this, & result); }
#endif
	Using_CodeOps( CodePreprocessCond );
	operator            Code();
	AST_PreprocessCond* operator->();
	AST_PreprocessCond* ast;
};

#ifdef GEN_EXECUTION_EXPRESSION_SUPPORT
struct CodeStmt
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator  Code();
	AST_Stmt* operator->();
	AST_Stmt* ast;
};

struct CodeStmt_Break
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Break );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator        Code();
	AST_Stmt_Break* operator->();
	AST_Stmt_Break* ast;
};

struct CodeStmt_Case
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Case );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator       Code();
	AST_Stmt_Case* operator->();
	AST_Stmt_Case* ast;
};

struct CodeStmt_Continue
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Continue );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator           Code();
	AST_Stmt_Continue* operator->();
	AST_Stmt_Continue* ast;
};

struct CodeStmt_Decl
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Decl );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator       Code();
	AST_Stmt_Decl* operator->();
	AST_Stmt_Decl* ast;
};

struct CodeStmt_Do
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Do );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator     Code();
	AST_Stmt_Do* operator->();
	AST_Stmt_Do* ast;
};

struct CodeStmt_Expr
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Expr );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator       Code();
	AST_Stmt_Expr* operator->();
	AST_Stmt_Expr* ast;
};

struct CodeStmt_Else
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Else );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator       Code();
	AST_Stmt_Else* operator->();
	AST_Stmt_Else* ast;
};

struct CodeStmt_If
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_If );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator     Code();
	AST_Stmt_If* operator->();
	AST_Stmt_If* ast;
};

struct CodeStmt_For
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_For );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator      Code();
	AST_Stmt_For* operator->();
	AST_Stmt_For* ast;
};

struct CodeStmt_Goto
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Goto );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator       Code();
	AST_Stmt_Goto* operator->();
	AST_Stmt_Goto* ast;
};

struct CodeStmt_Label
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Label );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator        Code();
	AST_Stmt_Label* operator->();
	AST_Stmt_Label* ast;
};

struct CodeStmt_Switch
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_Switch );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator       Code();
	AST_Stmt_Switch* operator->();
	AST_Stmt_Switch* ast;
};

struct CodeStmt_While
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStmt_While );
	forceinline StrBuilder to_strbuilder();
	forceinline void       to_strbuilder( StrBuilder& result );
#endif
	operator       Code();
	AST_Stmt_While* operator->();
	AST_Stmt_While* ast;
};
#endif

struct CodeTemplate
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeTemplate );
	forceinline StrBuilder to_strbuilder()                     { return template_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return template_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps( CodeTemplate );
	operator      Code();
	AST_Template* operator->();
	AST_Template* ast;
};

struct CodeTypename
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeTypename );
	forceinline StrBuilder to_strbuilder()                     { return typename_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return typename_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps( CodeTypename );
	operator      Code();
	AST_Typename* operator->();
	AST_Typename* ast;
};

struct CodeTypedef
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeTypedef );
	forceinline StrBuilder to_strbuilder()                     { return typedef_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return typedef_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps( CodeTypedef );
	operator     Code();
	AST_Typedef* operator->();
	AST_Typedef* ast;
};

struct CodeUnion
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeUnion );
	forceinline StrBuilder to_strbuilder()                         { return union_to_strbuilder(* this); }
	forceinline void       to_strbuilder_def( StrBuilder& result ) { return union_to_strbuilder_def(* this, & result); }
	forceinline void       to_strbuilder_fwd( StrBuilder& result ) { return union_to_strbuilder_fwd(* this, & result); }
#endif
	Using_CodeOps(CodeUnion);
	operator   Code();
	AST_Union* operator->();
	AST_Union* ast;
};

struct CodeUsing
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeUsing );
	forceinline StrBuilder to_strbuilder()                        { return using_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result )    { return using_to_strbuilder_ref(* this, & result); }
	forceinline void       to_strbuilder_ns( StrBuilder& result ) { return using_to_strbuilder_ns(* this, & result); }
#endif
	Using_CodeOps(CodeUsing);
	operator   Code();
	AST_Using* operator->();
	AST_Using* ast;
};

struct CodeVar
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeVar );
	forceinline StrBuilder to_strbuilder()                     { return var_to_strbuilder(* this); }
	forceinline void       to_strbuilder( StrBuilder& result ) { return var_to_strbuilder_ref(* this, & result); }
#endif
	Using_CodeOps(CodeVar);
	operator Code();
	AST_Var* operator->();
	AST_Var* ast;
};

struct CodeStruct
{
#if ! GEN_C_LIKE_CPP
	Using_Code( CodeStruct );
	forceinline void       add_interface( CodeTypename interface ) { return struct_add_interface(* this, interface); }
	forceinline StrBuilder to_strbuilder()                         { return struct_to_strbuilder(* this); }
	forceinline void       to_strbuilder_fwd( StrBuilder& result ) { return struct_to_strbuilder_fwd(* this, & result); }
	forceinline void       to_strbuilder_def( StrBuilder& result ) { return struct_to_strbuilder_def(* this, & result); }
#endif
	Using_CodeOps( CodeStruct );
	forceinline operator Code() { return * rcast( Code*, this ); }
	forceinline AST_Struct* operator->() {
		GEN_ASSERT(ast);
		return ast;
	}
	AST_Struct* ast;
};

#undef Define_CodeType
#undef Using_Code
#undef Using_CodeOps

#undef Verify_POD

struct InvalidCode_ImplictCaster
{
	// operator CodeBaseClass() const;
    operator Code              () const { return Code_Invalid; }
    operator CodeBody          () const { return cast(CodeBody,           Code_Invalid); }
    operator CodeAttributes    () const { return cast(CodeAttributes,     Code_Invalid); }
    operator CodeComment       () const { return cast(CodeComment,        Code_Invalid); }
    operator CodeClass         () const { return cast(CodeClass,          Code_Invalid); }
    operator CodeConstructor   () const { return cast(CodeConstructor,    Code_Invalid); }
    operator CodeDefine        () const { return cast(CodeDefine,         Code_Invalid); }
    operator CodeDefineParams  () const { return cast(CodeDefineParams,   Code_Invalid); }
    operator CodeDestructor    () const { return cast(CodeDestructor,     Code_Invalid); }
    operator CodeExec          () const { return cast(CodeExec,           Code_Invalid); }
    operator CodeEnum          () const { return cast(CodeEnum,           Code_Invalid); }
    operator CodeExtern        () const { return cast(CodeExtern,         Code_Invalid); }
    operator CodeInclude       () const { return cast(CodeInclude,        Code_Invalid); }
    operator CodeFriend        () const { return cast(CodeFriend,         Code_Invalid); }
    operator CodeFn            () const { return cast(CodeFn,             Code_Invalid); }
    operator CodeModule        () const { return cast(CodeModule,         Code_Invalid); }
    operator CodeNS            () const { return cast(CodeNS,             Code_Invalid); }
    operator CodeOperator      () const { return cast(CodeOperator,       Code_Invalid); }
    operator CodeOpCast        () const { return cast(CodeOpCast,         Code_Invalid); }
    operator CodeParams        () const { return cast(CodeParams,         Code_Invalid); }
    operator CodePragma        () const { return cast(CodePragma,         Code_Invalid); }
    operator CodePreprocessCond() const { return cast(CodePreprocessCond, Code_Invalid); }
    operator CodeSpecifiers    () const { return cast(CodeSpecifiers,     Code_Invalid); }
    operator CodeStruct        () const { return cast(CodeStruct,         Code_Invalid); }
    operator CodeTemplate      () const { return cast(CodeTemplate,       Code_Invalid); }
    operator CodeTypename      () const { return cast(CodeTypename,       Code_Invalid); }
    operator CodeTypedef       () const { return cast(CodeTypedef,        Code_Invalid); }
    operator CodeUnion         () const { return cast(CodeUnion,          Code_Invalid); }
    operator CodeUsing         () const { return cast(CodeUsing,          Code_Invalid); }
    operator CodeVar           () const { return cast(CodeVar,            Code_Invalid); }
};

struct NullCode_ImplicitCaster
{
    operator Code              () const { return {nullptr}; }
    operator CodeBody          () const { return {(AST_Body*)      nullptr}; }
    operator CodeAttributes    () const { return {(AST_Attributes*)nullptr}; }
    operator CodeComment       () const { return {nullptr}; }
    operator CodeClass         () const { return {nullptr}; }
    operator CodeConstructor   () const { return {nullptr}; }
    operator CodeDefine        () const { return {nullptr}; }
    operator CodeDefineParams  () const { return {nullptr}; }
    operator CodeDestructor    () const { return {nullptr}; }
    operator CodeExec          () const { return {nullptr}; }
    operator CodeEnum          () const { return {nullptr}; }
    operator CodeExtern        () const { return {nullptr}; }
    operator CodeInclude       () const { return {nullptr}; }
    operator CodeFriend        () const { return {nullptr}; }
    operator CodeFn            () const { return {nullptr}; }
    operator CodeModule        () const { return {nullptr}; }
    operator CodeNS            () const { return {nullptr}; }
    operator CodeOperator      () const { return {nullptr}; }
    operator CodeOpCast        () const { return {nullptr}; }
    operator CodeParams        () const { return {nullptr}; }
    operator CodePragma        () const { return {nullptr}; }
    operator CodePreprocessCond() const { return {nullptr}; }
    operator CodeSpecifiers    () const { return {nullptr}; }
    operator CodeStruct        () const { return {nullptr}; }
    operator CodeTemplate      () const { return {nullptr}; }
    operator CodeTypename      () const { return CodeTypename{(AST_Typename*)nullptr}; }
    operator CodeTypedef       () const { return {nullptr}; }
    operator CodeUnion         () const { return {nullptr}; }
    operator CodeUsing         () const { return {nullptr}; }
    operator CodeVar           () const { return {nullptr}; }
};

forceinline Code begin( CodeBody body)                   { return begin_CodeBody(body); }
forceinline Code end  ( CodeBody body )                  { return end_CodeBody(body); }
forceinline Code next ( CodeBody body, Code entry_iter ) { return next_CodeBody(body, entry_iter); }

forceinline CodeParams begin(CodeParams params)                        { return begin_CodeParams(params); }
forceinline CodeParams end  (CodeParams params)                        { return end_CodeParams(params); }
forceinline CodeParams next (CodeParams params, CodeParams entry_iter) { return next_CodeParams(params, entry_iter); }

forceinline Specifier* begin(CodeSpecifiers specifiers)                       { return begin_CodeSpecifiers(specifiers); }
forceinline Specifier* end  (CodeSpecifiers specifiers)                       { return end_CodeSpecifiers(specifiers); }
forceinline Specifier* next (CodeSpecifiers specifiers, Specifier& spec_iter) { return next_CodeSpecifiers(specifiers, & spec_iter); }

#if ! GEN_C_LIKE_CPP
GEN_OPTIMIZE_MAPPINGS_BEGIN

forceinline void       append              ( CodeBody body, Code     other )     { return body_append(body, other); }
forceinline void       append              ( CodeBody body, CodeBody other )     { return body_append_body(body, other); }
forceinline StrBuilder to_strbuilder       ( CodeBody body )                     { return body_to_strbuilder(body); }
forceinline void       to_strbuilder       ( CodeBody body, StrBuilder& result ) { return body_to_strbuilder_ref(body, & result); }
forceinline void       to_strbuilder_export( CodeBody body, StrBuilder& result ) { return body_to_strbuilder_export(body, & result); }

forceinline void       add_interface    ( CodeClass self, CodeTypename interface ) { return class_add_interface(self, interface); }
forceinline StrBuilder to_strbuilder    ( CodeClass self )                         { return class_to_strbuilder(self); }
forceinline void       to_strbuilder_def( CodeClass self, StrBuilder& result )     { return class_to_strbuilder_def(self, & result); }
forceinline void       to_strbuilder_fwd( CodeClass self, StrBuilder& result )     { return class_to_strbuilder_fwd(self, & result); }

forceinline void             append       (CodeDefineParams appendee, CodeDefineParams other ) {        params_append(cast(CodeParams, appendee), cast(CodeParams, other)); }
forceinline CodeDefineParams get          (CodeDefineParams params, s32 idx)                   { return (CodeDefineParams) (Code) params_get(cast(CodeParams, params), idx); }
forceinline bool             has_entries  (CodeDefineParams params )                           { return params_has_entries(cast(CodeParams, params)); }
forceinline StrBuilder       to_strbuilder(CodeDefineParams params )                           { return define_params_to_strbuilder(params); }
forceinline void             to_strbuilder(CodeDefineParams params, StrBuilder& result )       { return define_params_to_strbuilder_ref(params, & result); }

forceinline void       append       (CodeParams appendee, CodeParams other )   { return params_append(appendee, other); }
forceinline CodeParams get          (CodeParams params, s32 idx)               { return params_get(params, idx); }
forceinline bool       has_entries  (CodeParams params )                       { return params_has_entries(params); }
forceinline StrBuilder to_strbuilder(CodeParams params )                       { return params_to_strbuilder(params); }
forceinline void       to_strbuilder(CodeParams params, StrBuilder& result )   { return params_to_strbuilder_ref(params, & result); }
  
forceinline bool       append       (CodeSpecifiers specifiers, Specifier spec)       { return specifiers_append(specifiers, spec); }
forceinline s32        has          (CodeSpecifiers specifiers, Specifier spec)       { return specifiers_has(specifiers, spec); }
forceinline s32        remove       (CodeSpecifiers specifiers, Specifier to_remove ) { return specifiers_remove(specifiers, to_remove); }
forceinline StrBuilder to_strbuilder(CodeSpecifiers specifiers)                       { return specifiers_to_strbuilder(specifiers); }
forceinline void       to_strbuilder(CodeSpecifiers specifiers, StrBuilder& result)   { return specifiers_to_strbuilder_ref(specifiers, & result);  }

forceinline void       add_interface    (CodeStruct self, CodeTypename interface) { return struct_add_interface(self, interface); }
forceinline StrBuilder to_strbuilder    (CodeStruct self)                         { return struct_to_strbuilder(self); }
forceinline void       to_strbuilder_fwd(CodeStruct self, StrBuilder& result)     { return struct_to_strbuilder_fwd(self, & result); }
forceinline void       to_strbuilder_def(CodeStruct self, StrBuilder& result)     { return struct_to_strbuilder_def(self, & result); }

forceinline StrBuilder to_strbuilder(CodeAttributes attributes)                     { return attributes_to_strbuilder(attributes); }
forceinline void       to_strbuilder(CodeAttributes attributes, StrBuilder& result) { return attributes_to_strbuilder_ref(attributes, & result); }

forceinline StrBuilder to_strbuilder(CodeComment comment )                      { return comment_to_strbuilder(comment); }
forceinline void       to_strbuilder(CodeComment comment, StrBuilder& result )  { return comment_to_strbuilder_ref(comment, & result); }

forceinline StrBuilder to_strbuilder    (CodeConstructor constructor)                      { return constructor_to_strbuilder(constructor); }
forceinline void       to_strbuilder_def(CodeConstructor constructor, StrBuilder& result ) { return constructor_to_strbuilder_def(constructor, & result); }
forceinline void       to_strbuilder_fwd(CodeConstructor constructor, StrBuilder& result ) { return constructor_to_strbuilder_fwd(constructor, & result); }

forceinline StrBuilder to_strbuilder(CodeDefine self)                     { return define_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeDefine self, StrBuilder& result) { return define_to_strbuilder_ref(self, & result); }

forceinline StrBuilder to_strbuilder    (CodeDestructor destructor)                      { return destructor_to_strbuilder(destructor); }
forceinline void       to_strbuilder_def(CodeDestructor destructor, StrBuilder& result ) { return destructor_to_strbuilder_def(destructor, & result); }
forceinline void       to_strbuilder_fwd(CodeDestructor destructor, StrBuilder& result ) { return destructor_to_strbuilder_fwd(destructor, & result); }

forceinline StrBuilder to_strbuilder          (CodeEnum self)                      { return enum_to_strbuilder(self); }
forceinline void       to_strbuilder_def      (CodeEnum self, StrBuilder& result ) { return enum_to_strbuilder_def(self, & result); }
forceinline void       to_strbuilder_fwd      (CodeEnum self, StrBuilder& result ) { return enum_to_strbuilder_fwd(self, & result); }
forceinline void       to_strbuilder_class_def(CodeEnum self, StrBuilder& result ) { return enum_to_strbuilder_class_def(self, & result); }
forceinline void       to_strbuilder_class_fwd(CodeEnum self, StrBuilder& result ) { return enum_to_strbuilder_class_fwd(self, & result); }

forceinline StrBuilder to_strbuilder(CodeExec exec)                     { return exec_to_strbuilder(exec); }
forceinline void       to_strbuilder(CodeExec exec, StrBuilder& result) { return exec_to_strbuilder_ref(exec, & result); }

forceinline void to_strbuilder(CodeExtern self, StrBuilder& result) { return extern_to_strbuilder(self, & result); }

forceinline StrBuilder to_strbuilder(CodeInclude self)                     { return include_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeInclude self, StrBuilder& result) { return include_to_strbuilder_ref(self, & result); }

forceinline StrBuilder to_strbuilder(CodeFriend self)                     { return friend_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeFriend self, StrBuilder& result) { return friend_to_strbuilder_ref(self, & result); }

forceinline StrBuilder to_strbuilder    (CodeFn self)                     { return fn_to_strbuilder(self); }
forceinline void       to_strbuilder_def(CodeFn self, StrBuilder& result) { return fn_to_strbuilder_def(self, & result); }
forceinline void       to_strbuilder_fwd(CodeFn self, StrBuilder& result) { return fn_to_strbuilder_fwd(self, & result); }

forceinline StrBuilder to_strbuilder(CodeModule self)                     { return module_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeModule self, StrBuilder& result) { return module_to_strbuilder_ref(self, & result); }

forceinline StrBuilder to_strbuilder(CodeNS self)                     { return namespace_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeNS self, StrBuilder& result) { return namespace_to_strbuilder_ref(self,  & result); }

forceinline StrBuilder to_strbuilder    (CodeOperator self)                      { return code_op_to_strbuilder(self); }
forceinline void       to_strbuilder_fwd(CodeOperator self, StrBuilder& result ) { return code_op_to_strbuilder_fwd(self, & result); }
forceinline void       to_strbuilder_def(CodeOperator self, StrBuilder& result ) { return code_op_to_strbuilder_def(self, & result); }

forceinline StrBuilder to_strbuilder    (CodeOpCast op_cast )                     { return opcast_to_strbuilder(op_cast); }
forceinline void       to_strbuilder_def(CodeOpCast op_cast, StrBuilder& result ) { return opcast_to_strbuilder_def(op_cast, & result); }
forceinline void       to_strbuilder_fwd(CodeOpCast op_cast, StrBuilder& result ) { return opcast_to_strbuilder_fwd(op_cast, & result); }

forceinline StrBuilder to_strbuilder(CodePragma self)                     { return pragma_to_strbuilder(self); }
forceinline void       to_strbuilder(CodePragma self, StrBuilder& result) { return pragma_to_strbuilder_ref(self, & result); }

forceinline StrBuilder to_strbuilder       (CodePreprocessCond cond)                      { return preprocess_to_strbuilder(cond); }
forceinline void       to_strbuilder_if    (CodePreprocessCond cond, StrBuilder& result ) { return preprocess_to_strbuilder_if(cond, & result); }
forceinline void       to_strbuilder_ifdef (CodePreprocessCond cond, StrBuilder& result ) { return preprocess_to_strbuilder_ifdef(cond, & result); }
forceinline void       to_strbuilder_ifndef(CodePreprocessCond cond, StrBuilder& result ) { return preprocess_to_strbuilder_ifndef(cond, & result); }
forceinline void       to_strbuilder_elif  (CodePreprocessCond cond, StrBuilder& result ) { return preprocess_to_strbuilder_elif(cond, & result); }
forceinline void       to_strbuilder_else  (CodePreprocessCond cond, StrBuilder& result ) { return preprocess_to_strbuilder_else(cond, & result); }
forceinline void       to_strbuilder_endif (CodePreprocessCond cond, StrBuilder& result ) { return preprocess_to_strbuilder_endif(cond, & result); }

forceinline StrBuilder to_strbuilder(CodeTemplate self)                     { return template_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeTemplate self, StrBuilder& result) { return template_to_strbuilder_ref(self, & result); }

forceinline StrBuilder to_strbuilder(CodeTypename self)                     { return typename_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeTypename self, StrBuilder& result) { return typename_to_strbuilder_ref(self, & result); }

forceinline StrBuilder to_strbuilder(CodeTypedef self)                      { return typedef_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeTypedef self, StrBuilder& result ) { return typedef_to_strbuilder_ref(self, & result); }

forceinline StrBuilder to_strbuilder    (CodeUnion self)                     { return union_to_strbuilder(self); }
forceinline void       to_strbuilder_def(CodeUnion self, StrBuilder& result) { return union_to_strbuilder_def(self, & result); }
forceinline void       to_strbuilder_fwd(CodeUnion self, StrBuilder& result) { return union_to_strbuilder_fwd(self, & result); }

forceinline StrBuilder to_strbuilder   (CodeUsing op_cast )                     { return using_to_strbuilder(op_cast); }
forceinline void       to_strbuilder   (CodeUsing op_cast, StrBuilder& result ) { return using_to_strbuilder_ref(op_cast, & result); }
forceinline void       to_strbuilder_ns(CodeUsing op_cast, StrBuilder& result ) { return using_to_strbuilder_ns(op_cast, & result); }

forceinline StrBuilder to_strbuilder(CodeVar self)                     { return var_to_strbuilder(self); }
forceinline void       to_strbuilder(CodeVar self, StrBuilder& result) { return var_to_strbuilder_ref(self, & result); }

GEN_OPITMIZE_MAPPINGS_END
#endif //if GEN_C_LIKE_CPP

#pragma endregion Code Types C++
#endif //if GEN_COMPILER_CPP

#pragma region AST Types

/*
  ______   ______  ________      ________
 /      \ /      \|        \    |        \
|  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓▓▓▓▓▓▓     \▓▓▓▓▓▓▓▓__    __  ______   ______   _______
| ▓▓__| ▓▓ ▓▓___\▓▓  | ▓▓          | ▓▓  |  \  |  \/      \ /      \ /       \
| ▓▓    ▓▓\▓▓    \   | ▓▓          | ▓▓  | ▓▓  | ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\  ▓▓▓▓▓▓▓
| ▓▓▓▓▓▓▓▓_\▓▓▓▓▓▓\  | ▓▓          | ▓▓  | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓    ▓▓\▓▓    \
| ▓▓  | ▓▓  \__| ▓▓  | ▓▓          | ▓▓  | ▓▓__/ ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓_\▓▓▓▓▓▓\
| ▓▓  | ▓▓\▓▓    ▓▓  | ▓▓          | ▓▓   \▓▓    ▓▓ ▓▓    ▓▓\▓▓     \       ▓▓
 \▓▓   \▓▓ \▓▓▓▓▓▓    \▓▓           \▓▓   _\▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓\▓▓▓▓▓▓▓
                                         |  \__| ▓▓ ▓▓
                                          \▓▓    ▓▓ ▓▓
                                           \▓▓▓▓▓▓ \▓▓
*/

/*
	Show only relevant members of the AST for its type.
	AST* fields are replaced with Code types.
		- Guards assignemnts to AST* fields to ensure the AST is duplicated if assigned to another parent.
*/

struct AST_Body
{
	union {
		char  _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached Name;
	Code      Front;
	Code      Back;
	Token*    Tok;
	Code      Parent;
	CodeType  Type;
	char      _PAD_UNUSED_[ sizeof(ModuleFlag) ];
	s32       NumEntries;
};
static_assert( sizeof(AST_Body) == sizeof(AST), "ERROR: AST_Body is not the same size as AST");

// TODO(Ed): Support chaining attributes (Use parameter linkage pattern)
struct AST_Attributes
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		StrCached     Content;
	};
	StrCached         Name;
	Code              Prev;
	Code              Next;
	Token*            Tok;
	Code              Parent;
	CodeType          Type;
	char              _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Attributes) == sizeof(AST), "ERROR: AST_Attributes is not the same size as AST");

#if 0
struct AST_BaseClass
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached         Name;
	Code              Prev;
	Code              Next;
	Token*            Tok;
	Code              Parent;
	CodeType          Type;
	char              _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_BaseClass) == sizeof(AST), "ERROR: AST_BaseClass is not the same size as AST");
#endif

struct AST_Comment
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		StrCached  Content;
	};
	StrCached         Name;
	Code              Prev;
	Code              Next;
	Token*            Tok;
	Code              Parent;
	CodeType          Type;
	char              _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Comment) == sizeof(AST), "ERROR: AST_Comment is not the same size as AST");

struct AST_Class
{
	union {
		char                _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment     InlineCmt; // Only supported by forward declarations
			CodeAttributes  Attributes;
			CodeSpecifiers  Specs; // Support for final
			CodeTypename    ParentType;
			char            _PAD_PARAMS_[ sizeof(AST*) ];
			CodeBody        Body;
			char            _PAD_PROPERTIES_2_[ sizeof(AST*) ];
		};
	};
	StrCached               Name;
	CodeTypename            Prev;
	CodeTypename            Next;
	Token*                  Tok;
	Code                    Parent;
	CodeType                Type;
	ModuleFlag              ModuleFlags;
	AccessSpec              ParentAccess;
};
static_assert( sizeof(AST_Class) == sizeof(AST), "ERROR: AST_Class is not the same size as AST");

struct AST_Constructor
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment    InlineCmt; // Only supported by forward declarations
			char           _PAD_PROPERTIES_ [ sizeof(AST*) * 1 ];
			CodeSpecifiers Specs;
			Code           InitializerList;
			CodeParams     Params;
			Code           Body;
			char           _PAD_PROPERTIES_2_ [ sizeof(AST*) * 2 ];
		};
	};
	StrCached         Name;
	Code              Prev;
	Code              Next;
	Token*            Tok;
	Code              Parent;
	CodeType          Type;
	char              _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Constructor) == sizeof(AST), "ERROR: AST_Constructor is not the same size as AST");

struct AST_Define
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			char              _PAD_PROPERTIES_ [ sizeof(AST*) * 4 ];
			CodeDefineParams  Params;
			Code              Body; // Should be completely serialized for now to a: StrCached Content.
			char              _PAD_PROPERTIES_2_ [ sizeof(AST*) * 1 ];
		};
	};
	StrCached Name;
	Code      Prev;
	Code      Next;
	Token*    Tok;
	Code      Parent;
	CodeType  Type;
	char      _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Define) == sizeof(AST), "ERROR: AST_Define is not the same size as AST");

struct AST_DefineParams
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached         Name;
	CodeDefineParams  Last;
	CodeDefineParams  Next;
	Token*            Tok;
	Code              Parent;
	CodeType          Type;
	char              _PAD_UNUSED_[ sizeof(ModuleFlag) ];
	s32               NumEntries;
};
static_assert( sizeof(AST_DefineParams) == sizeof(AST), "ERROR: AST_DefineParams is not the same size as AST");

struct AST_Destructor
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment    InlineCmt;
			char           _PAD_PROPERTIES_ [ sizeof(AST*) * 1 ];
			CodeSpecifiers Specs;
			char           _PAD_PROPERTIES_2_ [ sizeof(AST*) * 2 ];
			Code           Body;
			char           _PAD_PROPERTIES_3_ [ sizeof(AST*) ];
		};
	};
	StrCached              Name;
	Code                   Prev;
	Code                   Next;
	Token*                 Tok;
	Code                   Parent;
	CodeType               Type;
	char                   _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Destructor) == sizeof(AST), "ERROR: AST_Destructor is not the same size as AST");

struct AST_Enum
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment    InlineCmt;
			CodeAttributes Attributes;
			char           _PAD_SPEC_  [ sizeof(AST*) ];
			CodeTypename   UnderlyingType;
			Code           UnderlyingTypeMacro;
			CodeBody       Body;
			char           _PAD_PROPERTIES_2_[ sizeof(AST*) ];
		};
	};
	StrCached              Name;
	Code                   Prev;
	Code                   Next;
	Token*                 Tok;
	Code                   Parent;
	CodeType               Type;
	ModuleFlag             ModuleFlags;
	char                   _PAD_UNUSED_[ sizeof(u32) ];
};
static_assert( sizeof(AST_Enum) == sizeof(AST), "ERROR: AST_Enum is not the same size as AST");

struct AST_Exec
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		StrCached  Content;
	};
	StrCached         Name;
	Code              Prev;
	Code              Next;
	Token*            Tok;
	Code              Parent;
	CodeType          Type;
	char              _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Exec) == sizeof(AST), "ERROR: AST_Exec is not the same size as AST");

#ifdef GEN_EXECUTION_EXPRESSION_SUPPORT
struct AST_Expr
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr) == sizeof(AST), "ERROR: AST_Expr is not the same size as AST");

struct AST_Expr_Assign
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Assign) == sizeof(AST), "ERROR: AST_Expr_Assign is not the same size as AST");

struct AST_Expr_Alignof
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Alignof) == sizeof(AST), "ERROR: AST_Expr_Alignof is not the same size as AST");

struct AST_Expr_Binary
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Binary) == sizeof(AST), "ERROR: AST_Expr_Binary is not the same size as AST");

struct AST_Expr_CStyleCast
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_CStyleCast) == sizeof(AST), "ERROR: AST_Expr_CStyleCast is not the same size as AST");

struct AST_Expr_FunctionalCast
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_FunctionalCast) == sizeof(AST), "ERROR: AST_Expr_FunctionalCast is not the same size as AST");

struct AST_Expr_CppCast
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_CppCast) == sizeof(AST), "ERROR: AST_Expr_CppCast is not the same size as AST");

struct AST_Expr_ProcCall
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_ProcCall) == sizeof(AST), "ERROR: AST_Expr_Identifier is not the same size as AST");

struct AST_Expr_Decltype
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Decltype) == sizeof(AST), "ERROR: AST_Expr_Decltype is not the same size as AST");

struct AST_Expr_Comma
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Comma) == sizeof(AST), "ERROR: AST_Expr_Comma is not the same size as AST");

struct AST_Expr_AMS
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_AMS) == sizeof(AST), "ERROR: AST_Expr_AMS is not the same size as AST");

struct AST_Expr_Sizeof
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Sizeof) == sizeof(AST), "ERROR: AST_Expr_Sizeof is not the same size as AST");

struct AST_Expr_Subscript
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Subscript) == sizeof(AST), "ERROR: AST_Expr_Subscript is not the same size as AST");

struct AST_Expr_Ternary
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Ternary) == sizeof(AST), "ERROR: AST_Expr_Ternary is not the same size as AST");

struct AST_Expr_UnaryPrefix
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_UnaryPrefix) == sizeof(AST), "ERROR: AST_Expr_UnaryPrefix is not the same size as AST");

struct AST_Expr_UnaryPostfix
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_UnaryPostfix) == sizeof(AST), "ERROR: AST_Expr_UnaryPostfix is not the same size as AST");

struct AST_Expr_Element
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached   Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Expr_Element) == sizeof(AST), "ERROR: AST_Expr_Element is not the same size as AST");
#endif

struct AST_Extern
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			char      _PAD_PROPERTIES_[ sizeof(AST*) * 5 ];
			CodeBody  Body;
			char      _PAD_PROPERTIES_2_[ sizeof(AST*) ];
		};
	};
	StrCached         Name;
	Code              Prev;
	Code              Next;
	Token*            Tok;
	Code              Parent;
	CodeType          Type;
	char              _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Extern) == sizeof(AST), "ERROR: AST_Extern is not the same size as AST");

struct AST_Include
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		StrCached  Content;
	};
	StrCached Name;
	Code      Prev;
	Code      Next;
	Token*    Tok;
	Code      Parent;
	CodeType  Type;
	char      _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Include) == sizeof(AST), "ERROR: AST_Include is not the same size as AST");

struct AST_Friend
{
	union {
		char            _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment InlineCmt;
			char        _PAD_PROPERTIES_[ sizeof(AST*) * 4 ];
			Code        Declaration;
			char        _PAD_PROPERTIES_2_[ sizeof(AST*) ];
		};
	};
	StrCached Name;
	Code      Prev;
	Code      Next;
	Token*    Tok;
	Code      Parent;
	CodeType  Type;
	char      _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Friend) == sizeof(AST), "ERROR: AST_Friend is not the same size as AST");

struct AST_Fn
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment     InlineCmt;
			CodeAttributes  Attributes;
			CodeSpecifiers  Specs;
			CodeTypename    ReturnType;
			CodeParams      Params;
			CodeBody        Body;
			Code            SuffixSpecs;  // Thanks Unreal
		};
	};
	StrCached  Name;
	Code       Prev;
	Code       Next;
	Token*     Tok;
	Code       Parent;
	CodeType   Type;
	ModuleFlag ModuleFlags;
	char       _PAD_UNUSED_[ sizeof(u32) ];
};
static_assert( sizeof(AST_Fn) == sizeof(AST), "ERROR: AST_Fn is not the same size as AST");

struct AST_Module
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached         Name;
	Code              Prev;
	Code              Next;
	Token*            Tok;
	Code              Parent;
	CodeType          Type;
	ModuleFlag        ModuleFlags;
	char             _PAD_UNUSED_[ sizeof(u32) ];
};
static_assert( sizeof(AST_Module) == sizeof(AST), "ERROR: AST_Module is not the same size as AST");

struct AST_NS
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct {
			char      _PAD_PROPERTIES_[ sizeof(AST*) * 5 ];
			CodeBody  Body;
			char      _PAD_PROPERTIES_2_[ sizeof(AST*) ];
		};
	};
	StrCached  Name;
	Code       Prev;
	Code       Next;
	Token*     Tok;
	Code       Parent;
	CodeType   Type;
	ModuleFlag ModuleFlags;
	char       _PAD_UNUSED_[ sizeof(u32) ];
};
static_assert( sizeof(AST_NS) == sizeof(AST), "ERROR: AST_NS is not the same size as AST");

struct AST_Operator
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment    InlineCmt;
			CodeAttributes Attributes;
			CodeSpecifiers Specs;
			CodeTypename   ReturnType;
			CodeParams 	   Params;
			CodeBody       Body;
			char           _PAD_PROPERTIES_ [ sizeof(AST*) ];
		};
	};
	StrCached  Name;
	Code       Prev;
	Code       Next;
	Token*     Tok;
	Code       Parent;
	CodeType   Type;
	ModuleFlag ModuleFlags;
	Operator   Op;
};
static_assert( sizeof(AST_Operator) == sizeof(AST), "ERROR: AST_Operator is not the same size as AST");

struct AST_OpCast
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment    InlineCmt;
			char           _PAD_PROPERTIES_[ sizeof(AST*)  ];
			CodeSpecifiers Specs;
			CodeTypename   ValueType;
			char           _PAD_PROPERTIES_2_[ sizeof(AST*) ];
			CodeBody       Body;
			char           _PAD_PROPERTIES_3_[ sizeof(AST*) ];
		};
	};
	StrCached Name;
	Code      Prev;
	Code      Next;
	Token*    Tok;
	Code      Parent;
	CodeType  Type;
	char      _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_OpCast) == sizeof(AST), "ERROR: AST_OpCast is not the same size as AST");

struct AST_Params
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			// TODO(Ed): Support attributes for parameters (Some prefix macros can be converted to that...)
			char         _PAD_PROPERTIES_2_[ sizeof(AST*) * 3 ];
			CodeTypename ValueType;
			Code         Macro;
			Code         Value;
			Code         PostNameMacro; // Thanks Unreal
			// char     _PAD_PROPERTIES_3_[sizeof( AST* )];
		};
	};
	StrCached  Name;
	CodeParams Last;
	CodeParams Next;
	Token*     Tok;
	Code       Parent;
	CodeType   Type;
	char       _PAD_UNUSED_[ sizeof(ModuleFlag) ];
	s32        NumEntries;
};
static_assert( sizeof(AST_Params) == sizeof(AST), "ERROR: AST_Params is not the same size as AST");

struct AST_Pragma
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		StrCached  Content;
	};
	StrCached Name;
	Code      Prev;
	Code      Next;
	Token*    Tok;
	Code      Parent;
	CodeType  Type;
	char      _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Pragma) == sizeof(AST), "ERROR: AST_Pragma is not the same size as AST");

struct AST_PreprocessCond
{
	union {
		char          _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		StrCached     Content;
	};
	StrCached Name;
	Code      Prev;
	Code      Next;
	Token*    Tok;
	Code      Parent;
	CodeType  Type;
	char      _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_PreprocessCond) == sizeof(AST), "ERROR: AST_PreprocessCond is not the same size as AST");

struct AST_Specifiers
{
	Specifier      ArrSpecs[ AST_ArrSpecs_Cap ];
	CodeSpecifiers NextSpecs;
	StrCached      Name;
	Code           Prev;
	Code           Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) ];
	s32            NumEntries;
};
static_assert( sizeof(AST_Specifiers) == sizeof(AST), "ERROR: AST_Specifier is not the same size as AST");

#ifdef GEN_EXECUTION_EXPRESSION_SUPPORT
struct AST_Stmt
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt) == sizeof(AST), "ERROR: AST_Stmt is not the same size as AST");

struct AST_Stmt_Break
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Break) == sizeof(AST), "ERROR: AST_Stmt_Break is not the same size as AST");

struct AST_Stmt_Case
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Case) == sizeof(AST), "ERROR: AST_Stmt_Case is not the same size as AST");

struct AST_Stmt_Continue
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Continue) == sizeof(AST), "ERROR: AST_Stmt_Continue is not the same size as AST");

struct AST_Stmt_Decl
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Decl) == sizeof(AST), "ERROR: AST_Stmt_Decl is not the same size as AST");

struct AST_Stmt_Do
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Do) == sizeof(AST), "ERROR: AST_Stmt_Do is not the same size as AST");

struct AST_Stmt_Expr
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Expr) == sizeof(AST), "ERROR: AST_Stmt_Expr is not the same size as AST");

struct AST_Stmt_Else
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Else) == sizeof(AST), "ERROR: AST_Stmt_Else is not the same size as AST");

struct AST_Stmt_If
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_If) == sizeof(AST), "ERROR: AST_Stmt_If is not the same size as AST");

struct AST_Stmt_For
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_For) == sizeof(AST), "ERROR: AST_Stmt_For is not the same size as AST");

struct AST_Stmt_Goto
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Goto) == sizeof(AST), "ERROR: AST_Stmt_Goto is not the same size as AST");

struct AST_Stmt_Label
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Label) == sizeof(AST), "ERROR: AST_Stmt_Label is not the same size as AST");

struct AST_Stmt_Switch
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_Switch) == sizeof(AST), "ERROR: AST_Stmt_Switch is not the same size as AST");

struct AST_Stmt_While
{
	union {
		char _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
	};
	StrCached      Name;
	CodeExpr       Prev;
	CodeExpr       Next;
	Token*         Tok;
	Code           Parent;
	CodeType       Type;
	char           _PAD_UNUSED_[ sizeof(ModuleFlag) + sizeof(u32) ];
};
static_assert( sizeof(AST_Stmt_While) == sizeof(AST), "ERROR: AST_Stmt_While is not the same size as AST");
#endif

struct AST_Struct
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment    InlineCmt;
			CodeAttributes Attributes;
			CodeSpecifiers Specs; // Support for final
			CodeTypename   ParentType;
			char           _PAD_PARAMS_[ sizeof(AST*) ];
			CodeBody       Body;
			char          _PAD_PROPERTIES_2_[ sizeof(AST*) ];
		};
	};
	StrCached              Name;
	CodeTypename           Prev;
	CodeTypename           Next;
	Token*                 Tok;
	Code                   Parent;
	CodeType               Type;
	ModuleFlag             ModuleFlags;
	AccessSpec             ParentAccess;
};
static_assert( sizeof(AST_Struct) == sizeof(AST), "ERROR: AST_Struct is not the same size as AST");

struct AST_Template
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			char           _PAD_PROPERTIES_[ sizeof(AST*) * 4 ];
			CodeParams 	   Params;
			Code           Declaration;
			char           _PAD_PROPERTIES_2_[ sizeof(AST*) ];
		};
	};
	StrCached  Name;
	Code       Prev;
	Code       Next;
	Token*     Tok;
	Code       Parent;
	CodeType   Type;
	ModuleFlag ModuleFlags;
	char       _PAD_UNUSED_[ sizeof(u32) ];
};
static_assert( sizeof(AST_Template) == sizeof(AST), "ERROR: AST_Template is not the same size as AST");

#if 0
// WIP... The type ast is going to become more advanced and lead to a major change to AST design.
struct AST_Type
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			char           _PAD_INLINE_CMT_[ sizeof(AST*) ];
			CodeAttributes  Attributes;
			CodeSpecifiers  Specs;
			Code            QualifierID;
			// CodeTypename ReturnType;      // Only used for function signatures
			// CodeParams    Params;          // Only used for function signatures
			Code            ArrExpr;
			// CodeSpecifiers SpecsFuncSuffix; // Only used for function signatures
		};
	};
	StrCached              Name;
	Code                   Prev;
	Code                   Next;
	Token*                 Tok;
	Code                   Parent;
	CodeType               Type;
	char                   _PAD_UNUSED_[ sizeof(ModuleFlag) ];
	b32                    IsParamPack;
};
static_assert( sizeof(AST_Type) == sizeof(AST), "ERROR: AST_Type is not the same size as AST");
#endif

struct AST_Typename
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			char           _PAD_INLINE_CMT_[ sizeof(AST*) ];
			CodeAttributes Attributes;
			CodeSpecifiers Specs;
			CodeTypename   ReturnType;      // Only used for function signatures
			CodeParams     Params;          // Only used for function signatures
			Code           ArrExpr;
			CodeSpecifiers SpecsFuncSuffix; // Only used for function signatures
		};
	};
	StrCached              Name;
	Code                   Prev;
	Code                   Next;
	Token*                 Tok;
	Code                   Parent;
	CodeType               Type;
	char                   _PAD_UNUSED_[ sizeof(ModuleFlag) ];
	struct {
		b16                IsParamPack;   // Used by typename to know if type should be considered a parameter pack.
		ETypenameTag       TypeTag;       // Used by typename to keep track of explicitly declared tags for the identifier (enum, struct, union)
	};
};
static_assert( sizeof(AST_Typename) == sizeof(AST), "ERROR: AST_Type is not the same size as AST");

struct AST_Typedef
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment    InlineCmt;
			char           _PAD_PROPERTIES_[ sizeof(AST*) * 2 ];
			Code           UnderlyingType;
			char           _PAD_PROPERTIES_2_[ sizeof(AST*) * 3 ];
		};
	};
	StrCached              Name;
	Code                   Prev;
	Code                   Next;
	Token*                 Tok;
	Code                   Parent;
	CodeType               Type;
	ModuleFlag             ModuleFlags;
	b32                    IsFunction;
};
static_assert( sizeof(AST_Typedef) == sizeof(AST), "ERROR: AST_Typedef is not the same size as AST");

struct AST_Union
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			char           _PAD_INLINE_CMT_[ sizeof(AST*) ];
			CodeAttributes Attributes;
			char           _PAD_PROPERTIES_[ sizeof(AST*) * 3 ];
			CodeBody       Body;
			char           _PAD_PROPERTIES_2_[ sizeof(AST*) ];
		};
	};
	StrCached  Name;
	Code       Prev;
	Code       Next;
	Token*     Tok;
	Code       Parent;
	CodeType   Type;
	ModuleFlag ModuleFlags;
	char       _PAD_UNUSED_[ sizeof(u32) ];
};
static_assert( sizeof(AST_Union) == sizeof(AST), "ERROR: AST_Union is not the same size as AST");

struct AST_Using
{
	union {
		char                _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment     InlineCmt;
			CodeAttributes  Attributes;
			char            _PAD_SPECS_     [ sizeof(AST*) ];
			CodeTypename    UnderlyingType;
			char            _PAD_PROPERTIES_[ sizeof(AST*) * 3 ];
		};
	};
	StrCached  Name;
	Code       Prev;
	Code       Next;
	Token*     Tok;
	Code       Parent;
	CodeType   Type;
	ModuleFlag ModuleFlags;
	char       _PAD_UNUSED_[ sizeof(u32) ];
};
static_assert( sizeof(AST_Using) == sizeof(AST), "ERROR: AST_Using is not the same size as AST");

struct AST_Var
{
	union {
		char               _PAD_[ sizeof(Specifier) * AST_ArrSpecs_Cap + sizeof(AST*) ];
		struct
		{
			CodeComment    InlineCmt;
			CodeAttributes Attributes;
			CodeSpecifiers Specs;
			CodeTypename   ValueType;
			Code           BitfieldSize;
			Code           Value;
			CodeVar        NextVar;
		};
	};
	StrCached  Name;
	Code       Prev;
	Code       Next;
	Token*     Tok;
	Code       Parent;
	CodeType   Type;
	ModuleFlag ModuleFlags;
	s32        VarParenthesizedInit;
};
static_assert( sizeof(AST_Var) == sizeof(AST), "ERROR: AST_Var is not the same size as AST");

#pragma endregion AST Types

#pragma endregion AST

#pragma region Gen Interface
/*
 /      \                       |      \          |  \                      /      \
|  ▓▓▓▓▓▓\ ______  _______       \▓▓▓▓▓▓_______  _| ▓▓_    ______   ______ |  ▓▓▓▓▓▓\ ______   _______  ______
| ▓▓ __\▓▓/      \|       \       | ▓▓ |       \|   ▓▓ \  /      \ /      \| ▓▓_  \▓▓|      \ /       \/      \
| ▓▓|    \  ▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\      | ▓▓ | ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓ \     \▓▓▓▓▓▓\  ▓▓▓▓▓▓▓  ▓▓▓▓▓▓\
| ▓▓ \▓▓▓▓ ▓▓    ▓▓ ▓▓  | ▓▓      | ▓▓ | ▓▓  | ▓▓ | ▓▓ __| ▓▓    ▓▓ ▓▓   \▓▓ ▓▓▓▓    /      ▓▓ ▓▓     | ▓▓    ▓▓
| ▓▓__| ▓▓ ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓     _| ▓▓_| ▓▓  | ▓▓ | ▓▓|  \ ▓▓▓▓▓▓▓▓ ▓▓     | ▓▓     |  ▓▓▓▓▓▓▓ ▓▓_____| ▓▓▓▓▓▓▓▓
 \▓▓    ▓▓\▓▓     \ ▓▓  | ▓▓    |   ▓▓ \ ▓▓  | ▓▓  \▓▓  ▓▓\▓▓     \ ▓▓     | ▓▓      \▓▓    ▓▓\▓▓     \\▓▓     \
  \▓▓▓▓▓▓  \▓▓▓▓▓▓▓\▓▓   \▓▓     \▓▓▓▓▓▓\▓▓   \▓▓   \▓▓▓▓  \▓▓▓▓▓▓▓\▓▓      \▓▓       \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓
*/

#if 0
enum LogLevel : u32
{
	Info,
	Warning,
	Panic,
};

struct LogEntry
{
	Str   msg;
	u32   line_num;
	void* data;
};

typedef void LoggerCallback(LogEntry entry);
#endif

// Note(Ed): This is subject to heavily change 
// with upcoming changes to the library's fallback (default) allocations strategy;
// and major changes to lexer/parser context usage.
struct Context
{
// User Configuration

// Persistent Data Allocation
	AllocatorInfo Allocator_DyanmicContainers; // By default will use a genral slab allocator (TODO(Ed): Currently does not)
	AllocatorInfo Allocator_Pool;              // By default will use the growing vmem reserve (TODO(Ed): Currently does not)
	AllocatorInfo Allocator_StrCache;          // By default will use a dedicated slab allocator (TODO(Ed): Currently does not)

// Temporary Allocation
	AllocatorInfo Allocator_Temp;

	// LoggerCallaback* log_callback; // TODO(Ed): Impl user logger callback as an option.

// Initalization config
	u32 Max_CommentLineLength; // Used by def_comment
	u32 Max_StrCacheLength;    // Any cached string longer than this is always allocated again.

	u32 InitSize_BuilderBuffer;
	u32 InitSize_CodePoolsArray;
	u32 InitSize_StringArenasArray;

	u32 CodePool_NumBlocks;

	// TODO(Ed): Review these... (No longer needed if using the proper allocation strategy)
	u32 InitSize_LexerTokens;
	u32 SizePer_StringArena;

	u32 InitSize_StrCacheTable;
	u32 InitSize_MacrosTable;

// TODO(Ed): Symbol Table
	// Keep track of all resolved symbols (naemspaced identifiers)

// Parser

	// Used by the lexer to persistently treat all these identifiers as preprocessor defines.
	// Populate with strings via gen::cache_str.
	// Functional defines must have format: id( ;at minimum to indicate that the define is only valid with arguments.
	MacroTable Macros;

// Backend

	// The fallback allocator is utilized if any fo the three above allocators is not specified by the user.
	u32 InitSize_Fallback_Allocator_Bucket_Size;
	Array(Arena) Fallback_AllocatorBuckets;

	StringTable token_fmt_map;

	// Array(Token) LexerTokens;

	Array(Pool)  CodePools;
	Array(Arena) StringArenas;

	StringTable StrCache;

	// TODO(Ed): This needs to be just handled by a parser context
	Array(Token) Lexer_Tokens;

	// TODO(Ed): Active parse context vs a parse result need to be separated conceptually
	ParseContext parser;

	// TODO(Ed): Formatting - This will eventually be in a separate struct when in the process of serialization of the builder.
	s32 temp_serialize_indent;
};

// TODO(Ed): Eventually this library should opt out of an implicit context for baseline implementation
// This would automatically make it viable for multi-threaded purposes among other things
// An implicit context interface will be provided instead as wrapper procedures as convience.
GEN_API extern Context* _ctx;

// Initialize the library. There first ctx initialized must exist for lifetime of other contextes that come after as its the one that
GEN_API void init(Context* ctx);

// Currently manually free's the arenas, code for checking for leaks.
// However on Windows at least, it doesn't need to occur as the OS will clean up after the process.
GEN_API void deinit(Context* ctx);

// Retrieves the active context (not usually needed, but here in case...)
GEN_API Context* get_context();

// Clears the allocations, but doesn't free the memoery, then calls init() again.
// Ease of use.
GEN_API void reset(Context* ctx);

GEN_API void set_context(Context* ctx);

// Mostly intended for the parser
GEN_API Macro* lookup_macro( Str Name );

// Alternative way to add a preprocess define entry for the lexer & parser to utilize 
// if the user doesn't want to use def_define
// Macros are tracked by name so if the name already exists the entry will be overwritten.
GEN_API void register_macro( Macro macro );

// Ease of use batch registration
GEN_API void register_macros( s32 num, ... );
GEN_API void register_macros_arr( s32 num, Macro* macros );

#if GEN_COMPILER_CPP
forceinline void register_macros( s32 num, Macro* macros ) { return register_macros_arr(num, macros); }
#endif

// Used internally to retrive or make string allocations.
// Strings are stored in a series of string arenas of fixed size (SizePer_StringArena)
GEN_API StrCached cache_str( Str str );

/*
	This provides a fresh Code AST.
	The gen interface use this as their method from getting a new AST object from the CodePool.
	Use this if you want to make your own API for formatting the supported Code Types.
*/
GEN_API Code make_code();

// Set these before calling gen's init() procedure.

#pragma region Upfront

GEN_API CodeAttributes def_attributes( Str content );
GEN_API CodeComment    def_comment   ( Str content );

struct Opts_def_struct {
	CodeBody       body;
	CodeTypename   parent;
	AccessSpec     parent_access;
	CodeAttributes attributes;
	CodeTypename*  interfaces;
	s32            num_interfaces;
	CodeSpecifiers specifiers; // Only used for final specifier for now.
	ModuleFlag     mflags;
};
GEN_API CodeClass def_class( Str name, Opts_def_struct opts GEN_PARAM_DEFAULT );

struct Opts_def_constructor {
	CodeParams params;
	Code      initializer_list;
	Code      body;
};
GEN_API CodeConstructor def_constructor( Opts_def_constructor opts GEN_PARAM_DEFAULT );

struct Opts_def_define {
	CodeDefineParams params;
	Str              content;
	MacroFlags       flags;
	b32              dont_register_to_preprocess_macros;
};
GEN_API CodeDefine def_define( Str name, MacroType type, Opts_def_define opts GEN_PARAM_DEFAULT );

struct Opts_def_destructor {
	Code           body;
	CodeSpecifiers specifiers;
};
GEN_API CodeDestructor def_destructor( Opts_def_destructor opts GEN_PARAM_DEFAULT );

struct Opts_def_enum {
	CodeBody       body;
	CodeTypename   type;
	EnumT          specifier;
	CodeAttributes attributes;
	ModuleFlag     mflags;
	Code           type_macro;
};
GEN_API CodeEnum def_enum( Str name, Opts_def_enum opts GEN_PARAM_DEFAULT );

GEN_API CodeExec   def_execution  ( Str content );
GEN_API CodeExtern def_extern_link( Str name, CodeBody body );
GEN_API CodeFriend def_friend     ( Code code );

struct Opts_def_function {
	CodeParams      params;
	CodeTypename    ret_type;
	CodeBody        body;
	CodeSpecifiers  specs;
	CodeAttributes  attrs;
	ModuleFlag      mflags;
};
GEN_API CodeFn def_function( Str name, Opts_def_function opts GEN_PARAM_DEFAULT );

struct Opts_def_include   { b32        foreign; };
struct Opts_def_module    { ModuleFlag mflags;  };
struct Opts_def_namespace { ModuleFlag mflags;  };
GEN_API CodeInclude def_include  ( Str content,             Opts_def_include   opts GEN_PARAM_DEFAULT );
GEN_API CodeModule  def_module   ( Str name,                Opts_def_module    opts GEN_PARAM_DEFAULT );
GEN_API CodeNS      def_namespace( Str name, CodeBody body, Opts_def_namespace opts GEN_PARAM_DEFAULT );

struct Opts_def_operator {
	CodeParams      params;
	CodeTypename    ret_type;
	CodeBody        body;
	CodeSpecifiers  specifiers;
	CodeAttributes  attributes;
	ModuleFlag      mflags;
};
GEN_API CodeOperator def_operator( Operator op, Str nspace, Opts_def_operator opts GEN_PARAM_DEFAULT );

struct Opts_def_operator_cast {
	CodeBody       body;
	CodeSpecifiers specs;
};
GEN_API CodeOpCast def_operator_cast( CodeTypename type, Opts_def_operator_cast opts GEN_PARAM_DEFAULT );

struct Opts_def_param { Code value; };
GEN_API CodeParams def_param ( CodeTypename type, Str name, Opts_def_param opts GEN_PARAM_DEFAULT );
GEN_API CodePragma def_pragma( Str directive );

GEN_API CodePreprocessCond def_preprocess_cond( EPreprocessCond type, Str content );

GEN_API CodeSpecifiers def_specifier( Specifier specifier );

GEN_API CodeStruct def_struct( Str name, Opts_def_struct opts GEN_PARAM_DEFAULT );

struct Opts_def_template { ModuleFlag mflags; };
GEN_API CodeTemplate def_template( CodeParams params, Code definition, Opts_def_template opts GEN_PARAM_DEFAULT );

struct Opts_def_type {
	ETypenameTag   type_tag;
	Code           array_expr;
	CodeSpecifiers specifiers;
	CodeAttributes attributes;
};
GEN_API CodeTypename def_type( Str name, Opts_def_type opts GEN_PARAM_DEFAULT );

struct Opts_def_typedef {
	CodeAttributes attributes;
	ModuleFlag     mflags;
};
GEN_API CodeTypedef def_typedef( Str name, Code type, Opts_def_typedef opts GEN_PARAM_DEFAULT );

struct Opts_def_union {
	CodeAttributes attributes;
	ModuleFlag     mflags;
};
GEN_API CodeUnion def_union( Str name, CodeBody body, Opts_def_union opts GEN_PARAM_DEFAULT );

struct Opts_def_using {
	CodeAttributes attributes;
	ModuleFlag     mflags;
};
GEN_API CodeUsing def_using( Str name, CodeTypename type, Opts_def_using opts GEN_PARAM_DEFAULT );

GEN_API CodeUsing def_using_namespace( Str name );

struct Opts_def_variable
{
	Code           value;
	CodeSpecifiers specifiers;
	CodeAttributes attributes;
	ModuleFlag     mflags;
};
GEN_API CodeVar def_variable( CodeTypename type, Str name, Opts_def_variable opts GEN_PARAM_DEFAULT );

// Constructs an empty body. Use AST::validate_body() to check if the body is was has valid entries.
CodeBody def_body( CodeType type );

// There are two options for defining a struct body, either varadically provided with the args macro to auto-deduce the arg num,
/// or provide as an array of Code objects.

GEN_API CodeBody         def_class_body           ( s32 num, ... );
GEN_API CodeBody         def_class_body_arr       ( s32 num, Code* codes );
GEN_API CodeDefineParams def_define_params        ( s32 num, ... );
GEN_API CodeDefineParams def_define_params_arr    ( s32 num, CodeDefineParams* codes );
GEN_API CodeBody         def_enum_body            ( s32 num, ... );
GEN_API CodeBody         def_enum_body_arr        ( s32 num, Code* codes );
GEN_API CodeBody         def_export_body          ( s32 num, ... );
GEN_API CodeBody         def_export_body_arr      ( s32 num, Code* codes);
GEN_API CodeBody         def_extern_link_body     ( s32 num, ... );
GEN_API CodeBody         def_extern_link_body_arr ( s32 num, Code* codes );
GEN_API CodeBody         def_function_body        ( s32 num, ... );
GEN_API CodeBody         def_function_body_arr    ( s32 num, Code* codes );
GEN_API CodeBody         def_global_body          ( s32 num, ... );
GEN_API CodeBody         def_global_body_arr      ( s32 num, Code* codes );
GEN_API CodeBody         def_namespace_body       ( s32 num, ... );
GEN_API CodeBody         def_namespace_body_arr   ( s32 num, Code* codes );
GEN_API CodeParams       def_params               ( s32 num, ... );
GEN_API CodeParams       def_params_arr           ( s32 num, CodeParams* params );
GEN_API CodeSpecifiers   def_specifiers           ( s32 num, ... );
GEN_API CodeSpecifiers   def_specifiers_arr       ( s32 num, Specifier* specs );
GEN_API CodeBody         def_struct_body          ( s32 num, ... );
GEN_API CodeBody         def_struct_body_arr      ( s32 num, Code* codes );
GEN_API CodeBody         def_union_body           ( s32 num, ... );
GEN_API CodeBody         def_union_body_arr       ( s32 num, Code* codes );

#if GEN_COMPILER_CPP
forceinline CodeBody         def_class_body      ( s32 num, Code* codes )             { return def_class_body_arr(num, codes); }
forceinline CodeDefineParams def_define_params   ( s32 num, CodeDefineParams* codes ) { return def_define_params_arr(num, codes); }
forceinline CodeBody         def_enum_body       ( s32 num, Code* codes )             { return def_enum_body_arr(num, codes); }
forceinline CodeBody         def_export_body     ( s32 num, Code* codes)              { return def_export_body_arr(num, codes); }
forceinline CodeBody         def_extern_link_body( s32 num, Code* codes )             { return def_extern_link_body_arr(num, codes); }
forceinline CodeBody         def_function_body   ( s32 num, Code* codes )             { return def_function_body_arr(num, codes); }
forceinline CodeBody         def_global_body     ( s32 num, Code* codes )             { return def_global_body_arr(num, codes); }
forceinline CodeBody         def_namespace_body  ( s32 num, Code* codes )             { return def_namespace_body_arr(num, codes); }
forceinline CodeParams       def_params          ( s32 num, CodeParams* params )      { return def_params_arr(num, params); }
forceinline CodeSpecifiers   def_specifiers      ( s32 num, Specifier* specs )        { return def_specifiers_arr(num, specs); }
forceinline CodeBody         def_struct_body     ( s32 num, Code* codes )             { return def_struct_body_arr(num, codes); }
forceinline CodeBody         def_union_body      ( s32 num, Code* codes )             { return def_union_body_arr(num, codes); }
#endif

#pragma endregion Upfront

#pragma region Parsing

#if 0
struct StackNode
{
	StackNode* Prev;

	Token Start;
	Token Name;       // The name of the AST node (if parsed)
	Str  FailedProc; // The name of the procedure that failed
};
// Stack nodes are allocated the error's allocator

struct Error
{
	StrBuilder     message;
	StackNode* context_stack;
};

struct ParseInfo
{
	Arena FileMem;
	Arena TokMem;
	Arena CodeMem;

	FileContents FileContent;
	Array<Token> Tokens;
	Array<Error> Errors;
	// Errors are allocated to a dedicated general arena.
};

CodeBody parse_file( Str path );
#endif

GEN_API CodeClass       parse_class        ( Str class_def       );
GEN_API CodeConstructor parse_constructor  ( Str constructor_def );
GEN_API CodeDefine      parse_define       ( Str define_def      );
GEN_API CodeDestructor  parse_destructor   ( Str destructor_def  );
GEN_API CodeEnum        parse_enum         ( Str enum_def        );
GEN_API CodeBody        parse_export_body  ( Str export_def      );
GEN_API CodeExtern      parse_extern_link  ( Str exten_link_def  );
GEN_API CodeFriend      parse_friend       ( Str friend_def      );
GEN_API CodeFn          parse_function     ( Str fn_def          );
GEN_API CodeBody        parse_global_body  ( Str body_def        );
GEN_API CodeNS          parse_namespace    ( Str namespace_def   );
GEN_API CodeOperator    parse_operator     ( Str operator_def    );
GEN_API CodeOpCast      parse_operator_cast( Str operator_def    );
GEN_API CodeStruct      parse_struct       ( Str struct_def      );
GEN_API CodeTemplate    parse_template     ( Str template_def    );
GEN_API CodeTypename    parse_type         ( Str type_def        );
GEN_API CodeTypedef     parse_typedef      ( Str typedef_def     );
GEN_API CodeUnion       parse_union        ( Str union_def       );
GEN_API CodeUsing       parse_using        ( Str using_def       );
GEN_API CodeVar         parse_variable     ( Str var_def         );

#pragma endregion Parsing

#pragma region Untyped text

GEN_API ssize token_fmt_va( char* buf, usize buf_size, s32 num_tokens, va_list va );
//! Do not use directly. Use the token_fmt macro instead.
Str   token_fmt_impl( ssize, ... );

GEN_API Code untyped_str( Str content);
GEN_API Code untyped_fmt      ( char const* fmt, ... );
GEN_API Code untyped_token_fmt( s32 num_tokens, char const* fmt, ... );

#pragma endregion Untyped text

#pragma region Macros

#ifndef gen_main
#define gen_main main
#endif

#ifndef name
//	Convienence for defining any name used with the gen api.
//  Lets you provide the length and string literal to the functions without the need for the DSL.
#	if GEN_COMPILER_C
#		define name( Id_ ) (Str){ stringize(Id_), sizeof(stringize( Id_ )) - 1 }
#	else
#		define name( Id_ )  Str { stringize(Id_), sizeof(stringize( Id_ )) - 1 }
#	endif
#endif

#ifndef code
//  Same as name just used to indicate intention of literal for code instead of names.
#	if GEN_COMPILER_C
#		define code( ... ) (Str){ stringize( __VA_ARGS__ ), sizeof(stringize(__VA_ARGS__)) - 1 }
#	else
#		define code( ... )  Str { stringize( __VA_ARGS__ ), sizeof(stringize(__VA_ARGS__)) - 1 }
#	endif
#endif

#ifndef args
// Provides the number of arguments while passing args inplace.
#define args( ... ) num_args( __VA_ARGS__ ), __VA_ARGS__
#endif

#ifndef code_str
// Just wrappers over common untyped code definition constructions.
#define code_str( ... ) GEN_NS untyped_str( code( __VA_ARGS__ ) )
#endif

#ifndef code_fmt
#define code_fmt( ... ) GEN_NS untyped_str( token_fmt( __VA_ARGS__ ) )
#endif

#ifndef parse_fmt
#define parse_fmt( type, ... ) GEN_NS parse_##type( token_fmt( __VA_ARGS__ ) )
#endif

#ifndef token_fmt
/*
Takes a format string (char const*) and a list of tokens (Str) and returns a Str of the formatted string.
Tokens are provided in '<'identifier'>' format where '<' '>' are just angle brackets (you can change it in token_fmt_va)
---------------------------------------------------------
	Example - A string with:
		typedef <type> <name> <name>;
	Will have a token_fmt arguments populated with:
		"type", str_for_type,
		"name", str_for_name,
	and:
		stringize( typedef <type> <name> <name>; )
-----------------------------------------------------------
So the full call for this example would be:
	token_fmt(
		"type", str_for_type
	,	"name", str_for_name
	,	stringize(
		typedef <type> <name> <name>
	));
!----------------------------------------------------------
! Note: token_fmt_va is whitespace sensitive for the tokens.
! This can be alleviated by skipping whitespace between brackets but it was choosen to not have that implementation by default.
*/
#define token_fmt( ... ) GEN_NS token_fmt_impl( (num_args( __VA_ARGS__ ) + 1) / 2, __VA_ARGS__ )
#endif

#pragma endregion Macros

#pragma endregion Gen Interface

#pragma region Constants
// Predefined typename codes. Are set to readonly and are setup during gen::init()

GEN_API extern Macro enum_underlying_macro;

GEN_API extern Code access_public;
GEN_API extern Code access_protected;
GEN_API extern Code access_private;

GEN_API extern CodeAttributes attrib_api_export;
GEN_API extern CodeAttributes attrib_api_import;

GEN_API extern Code module_global_fragment;
GEN_API extern Code module_private_fragment;

GEN_API extern Code fmt_newline;

GEN_API extern CodePragma pragma_once;

GEN_API extern CodeParams param_varadic;

GEN_API extern CodePreprocessCond preprocess_else;
GEN_API extern CodePreprocessCond preprocess_endif;

GEN_API extern CodeSpecifiers spec_const;
GEN_API extern CodeSpecifiers spec_consteval;
GEN_API extern CodeSpecifiers spec_constexpr;
GEN_API extern CodeSpecifiers spec_constinit;
GEN_API extern CodeSpecifiers spec_extern_linkage;
GEN_API extern CodeSpecifiers spec_final;
GEN_API extern CodeSpecifiers spec_forceinline;
GEN_API extern CodeSpecifiers spec_global;
GEN_API extern CodeSpecifiers spec_inline;
GEN_API extern CodeSpecifiers spec_internal_linkage;
GEN_API extern CodeSpecifiers spec_local_persist;
GEN_API extern CodeSpecifiers spec_mutable;
GEN_API extern CodeSpecifiers spec_neverinline;
GEN_API extern CodeSpecifiers spec_noexcept;
GEN_API extern CodeSpecifiers spec_override;
GEN_API extern CodeSpecifiers spec_ptr;
GEN_API extern CodeSpecifiers spec_pure;
GEN_API extern CodeSpecifiers spec_ref;
GEN_API extern CodeSpecifiers spec_register;
GEN_API extern CodeSpecifiers spec_rvalue;
GEN_API extern CodeSpecifiers spec_static_member;
GEN_API extern CodeSpecifiers spec_thread_local;
GEN_API extern CodeSpecifiers spec_virtual;
GEN_API extern CodeSpecifiers spec_volatile;

GEN_API extern CodeTypename t_empty; // Used with varaidc parameters. (Exposing just in case its useful for another circumstance)
GEN_API extern CodeTypename t_auto;
GEN_API extern CodeTypename t_void;
GEN_API extern CodeTypename t_int;
GEN_API extern CodeTypename t_bool;
GEN_API extern CodeTypename t_char;
GEN_API extern CodeTypename t_wchar_t;
GEN_API extern CodeTypename t_class;
GEN_API extern CodeTypename t_typename;

#ifdef GEN_DEFINE_LIBRARY_CODE_CONSTANTS
	GEN_API extern CodeTypename t_b32;

	GEN_API extern CodeTypename t_s8;
	GEN_API extern CodeTypename t_s16;
	GEN_API extern CodeTypename t_s32;
	GEN_API extern CodeTypename t_s64;

	GEN_API extern CodeTypename t_u8;
	GEN_API extern CodeTypename t_u16;
	GEN_API extern CodeTypename t_u32;
	GEN_API extern CodeTypename t_u64;

	GEN_API extern CodeTypename t_ssize;
	GEN_API extern CodeTypename t_usize;

	GEN_API extern CodeTypename t_f32;
	GEN_API extern CodeTypename t_f64;
#endif

#pragma endregion Constants

#pragma region Inlines

#pragma region Serialization
inline
StrBuilder attributes_to_strbuilder(CodeAttributes attributes) {
	GEN_ASSERT(attributes);
	char* raw = ccast(char*, str_duplicate( attributes->Content, get_context()->Allocator_Temp ).Ptr);
	StrBuilder result = { raw };
	return result;
}

inline
void attributes_to_strbuilder_ref(CodeAttributes attributes, StrBuilder* result) {
	GEN_ASSERT(attributes);
	GEN_ASSERT(result);
	strbuilder_append_str(result, attributes->Content);
}

inline
StrBuilder comment_to_strbuilder(CodeComment comment) {
	GEN_ASSERT(comment);
	char* raw = ccast(char*, str_duplicate( comment->Content, get_context()->Allocator_Temp ).Ptr);
	StrBuilder result = { raw };
	return result;
}

inline
void body_to_strbuilder_ref( CodeBody body, StrBuilder* result )
{
	GEN_ASSERT(body   != nullptr);
	GEN_ASSERT(result != nullptr);
	Code curr = body->Front;
	s32  left = body->NumEntries;
	while ( left -- )
	{
		code_to_strbuilder_ref(curr, result);
		// strbuilder_append_fmt( result, "%SB", code_to_strbuilder(curr) );
		curr = curr->Next;
	}
}

inline
void comment_to_strbuilder_ref(CodeComment comment, StrBuilder* result) {
	GEN_ASSERT(comment);
	GEN_ASSERT(result);
	strbuilder_append_str(result, comment->Content);
}

inline
StrBuilder define_to_strbuilder(CodeDefine define)
{
	GEN_ASSERT(define);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 512 );
	define_to_strbuilder_ref(define, & result);
	return result;
}

inline
StrBuilder define_params_to_strbuilder(CodeDefineParams params)
{
	GEN_ASSERT(params);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 128 );
	define_params_to_strbuilder_ref( params, & result );
	return result;
}

inline
StrBuilder exec_to_strbuilder(CodeExec exec)
{
	GEN_ASSERT(exec);
	char* raw = ccast(char*, str_duplicate( exec->Content, _ctx->Allocator_Temp ).Ptr);
	StrBuilder result = { raw };
	return result;
}

inline
void exec_to_strbuilder_ref(CodeExec exec, StrBuilder* result) {
	GEN_ASSERT(exec);
	GEN_ASSERT(result);
	strbuilder_append_str(result, exec->Content);
}

inline
void extern_to_strbuilder(CodeExtern self, StrBuilder* result )
{
	GEN_ASSERT(self);
	GEN_ASSERT(result);
	if ( self->Body )
		strbuilder_append_fmt( result, "extern \"%S\"\n{\n%SB\n}\n", self->Name, body_to_strbuilder(self->Body) );
	else
		strbuilder_append_fmt( result, "extern \"%S\"\n{}\n", self->Name );
}

inline
StrBuilder friend_to_strbuilder(CodeFriend self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 256 );
	friend_to_strbuilder_ref( self, & result );
	return result;
}

inline
void friend_to_strbuilder_ref(CodeFriend self, StrBuilder* result )
{
	GEN_ASSERT(self);
	GEN_ASSERT(result);
	strbuilder_append_fmt( result, "friend %SB", code_to_strbuilder(self->Declaration) );

	if ( self->Declaration->Type != CT_Function && self->Declaration->Type != CT_Operator && (* result)[ strbuilder_length(* result) - 1 ] != ';' )
	{
		strbuilder_append_str( result, txt(";") );
	}

	if ( self->InlineCmt )
		strbuilder_append_fmt( result, "  %S", self->InlineCmt->Content );
	else
		strbuilder_append_str( result, txt("\n"));
}

inline
StrBuilder include_to_strbuilder(CodeInclude include)
{
	GEN_ASSERT(include);
	return strbuilder_fmt_buf( _ctx->Allocator_Temp, "#include %S\n", include->Content );
}

inline
void include_to_strbuilder_ref( CodeInclude include, StrBuilder* result )
{
	GEN_ASSERT(include);
	GEN_ASSERT(result);
	strbuilder_append_fmt( result, "#include %S\n", include->Content );
}

inline
StrBuilder module_to_strbuilder(CodeModule self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 64 );
	module_to_strbuilder_ref( self, & result );
	return result;
}

inline
StrBuilder namespace_to_strbuilder(CodeNS self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 512 );
	namespace_to_strbuilder_ref( self, & result );
	return result;
}

inline
void namespace_to_strbuilder_ref(CodeNS self, StrBuilder* result )
{
	GEN_ASSERT(self);
	GEN_ASSERT(result);
	if ( bitfield_is_set( u32, self->ModuleFlags, ModuleFlag_Export ))
		strbuilder_append_str( result, txt("export ") );

	strbuilder_append_fmt( result, "namespace %S\n{\n%SB\n}\n", self->Name, body_to_strbuilder(self->Body) );
}

inline
StrBuilder params_to_strbuilder(CodeParams self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 128 );
	params_to_strbuilder_ref( self, & result );
	return result;
}

inline
StrBuilder pragma_to_strbuilder(CodePragma self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 256 );
	pragma_to_strbuilder_ref( self, & result );
	return result;
}

inline
void pragma_to_strbuilder_ref(CodePragma self, StrBuilder* result )
{
	GEN_ASSERT(self);
	GEN_ASSERT(result);
	strbuilder_append_fmt( result, "#pragma %S\n", self->Content );
}

inline
void preprocess_to_strbuilder_if(CodePreprocessCond cond, StrBuilder* result )
{
	GEN_ASSERT(cond);
	GEN_ASSERT(result);
	strbuilder_append_fmt( result, "#if %S", cond->Content );
}

inline
void preprocess_to_strbuilder_ifdef(CodePreprocessCond cond, StrBuilder* result )
{
	GEN_ASSERT(cond);
	GEN_ASSERT(result);
	strbuilder_append_fmt( result, "#ifdef %S\n", cond->Content );
}

inline
void preprocess_to_strbuilder_ifndef(CodePreprocessCond cond, StrBuilder* result )
{
	GEN_ASSERT(cond);
	GEN_ASSERT(result);
	strbuilder_append_fmt( result, "#ifndef %S", cond->Content );
}

inline
void preprocess_to_strbuilder_elif(CodePreprocessCond cond, StrBuilder* result )
{
	GEN_ASSERT(cond);
	GEN_ASSERT(result);
	strbuilder_append_fmt( result, "#elif %S\n", cond->Content );
}

inline
void preprocess_to_strbuilder_else(CodePreprocessCond cond, StrBuilder* result )
{
	GEN_ASSERT(cond);
	GEN_ASSERT(result);
	strbuilder_append_str( result, txt("#else\n") );
}

inline
void preprocess_to_strbuilder_endif(CodePreprocessCond cond, StrBuilder* result )
{
	GEN_ASSERT(cond);
	GEN_ASSERT(result);
	strbuilder_append_str( result, txt("#endif\n") );
}

inline
StrBuilder specifiers_to_strbuilder(CodeSpecifiers self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 64 );
	specifiers_to_strbuilder_ref( self, & result );
	return result;
}

inline
StrBuilder template_to_strbuilder(CodeTemplate self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 1024 );
	template_to_strbuilder_ref( self, & result );
	return result;
}

inline
StrBuilder typedef_to_strbuilder(CodeTypedef self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 128 );
	typedef_to_strbuilder_ref( self, & result );
	return result;
}

inline
StrBuilder typename_to_strbuilder(CodeTypename self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_str( _ctx->Allocator_Temp, txt("") );
	typename_to_strbuilder_ref( self, & result );
	return result;
}

inline
StrBuilder using_to_strbuilder(CodeUsing self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( _ctx->Allocator_Temp, 128 );
	switch ( self->Type )
	{
		case CT_Using:
			using_to_strbuilder_ref( self, & result );
		break;
		case CT_Using_Namespace:
			using_to_strbuilder_ns( self, & result );
		break;
	}
	return result;
}

inline
void using_to_strbuilder_ns(CodeUsing self, StrBuilder* result )
{
	GEN_ASSERT(self);
	GEN_ASSERT(result);
	if ( self->InlineCmt )
		strbuilder_append_fmt( result, "using namespace $S;  %S", self->Name, self->InlineCmt->Content );
	else
		strbuilder_append_fmt( result, "using namespace %S;\n", self->Name );
}

inline
StrBuilder var_to_strbuilder(CodeVar self)
{
	GEN_ASSERT(self);
	StrBuilder result = strbuilder_make_reserve( get_context()->Allocator_Temp, 256 );
	var_to_strbuilder_ref( self, & result );
	return result;
}
#pragma endregion Serialization

#pragma region Code
inline
void code_append( Code self, Code other )
{
	GEN_ASSERT(self);
	GEN_ASSERT(other);
	GEN_ASSERT_MSG(self != other, "Attempted to recursively append Code AST to itself.");

	if ( other->Parent != nullptr )
		other = code_duplicate(other);

	other->Parent = self;

	if ( self->Front == nullptr )
	{
		self->Front = other;
		self->Back  = other;

		self->NumEntries++;
		return;
	}

	Code
	Current       = self->Back;
	Current->Next = other;
	other->Prev   = Current;
	self->Back    = other;
	self->NumEntries++;
}
inline
bool code_is_body(Code self)
{
	GEN_ASSERT(self);
	switch (self->Type)
	{
		case CT_Enum_Body:
		case CT_Class_Body:
		case CT_Union_Body:
		case CT_Export_Body:
		case CT_Global_Body:
		case CT_Struct_Body:
		case CT_Function_Body:
		case CT_Namespace_Body:
		case CT_Extern_Linkage_Body:
			return true;
	}
	return false;
}
inline
Code* code_entry( Code self, u32 idx )
{
	GEN_ASSERT(self != nullptr);
	Code* current = & self->Front;
	while ( idx >= 0 && current != nullptr )
	{
		if ( idx == 0 )
			return rcast( Code*, current);

		current = & ( * current )->Next;
		idx--;
	}

	return rcast( Code*, current);
}
forceinline
bool code_is_valid(Code self)
{
	GEN_ASSERT(self);
	return self != nullptr && self->Type != CT_Invalid;
}
forceinline
bool code_has_entries(Code self)
{
	GEN_ASSERT(self);
	return self->NumEntries > 0;
}
forceinline
void code_set_global(Code self)
{
	if ( self == nullptr )
	{
		log_failure("Code::set_global: Cannot set code as global, AST is null!");
		return;
	}

	self->Parent = Code_Global;
}
#if GEN_COMPILER_CPP
forceinline
Code& Code::operator ++()
{
	if ( ast )
		ast = ast->Next.ast;

	return * this;
}
#endif
forceinline
Str code_type_str(Code self)
{
	GEN_ASSERT(self != nullptr);
	return codetype_to_str( self->Type );
}
#pragma endregion Code

#pragma region CodeBody
inline
void body_append( CodeBody self, Code other )
{
	GEN_ASSERT(self);
	GEN_ASSERT(other);

	if (code_is_body(other)) {
		body_append_body( self, cast(CodeBody, other) );
		return;
	}

	code_append( cast(Code, self), other );
}
inline
void body_append_body( CodeBody self, CodeBody body )
{
	GEN_ASSERT(self);
	GEN_ASSERT(body);
	GEN_ASSERT_MSG(self != body, "Attempted to append body to itself.");

	for ( Code entry = begin_CodeBody(body); entry != end_CodeBody(body); entry = next_CodeBody(body, entry) ) {
		body_append( self, entry );
	}
}
inline
Code begin_CodeBody( CodeBody body) {
	GEN_ASSERT(body);
	if ( body != nullptr )
		return body->Front;

	return NullCode;
}
forceinline
Code end_CodeBody(CodeBody body ){
	GEN_ASSERT(body);
	return body->Back->Next;
}
inline
Code next_CodeBody(CodeBody body, Code entry) {
	GEN_ASSERT(body);
	GEN_ASSERT(entry);
	return entry->Next;
}
#pragma endregion CodeBody

#pragma region CodeClass
inline
void class_add_interface( CodeClass self, CodeTypename type )
{
	GEN_ASSERT(self);
	GEN_ASSERT(type);
	CodeTypename possible_slot = self->ParentType;
	if ( possible_slot != nullptr )
	{
		// Were adding an interface to parent type, so we need to make sure the parent type is public.
		self->ParentAccess = AccessSpec_Public;
		// If your planning on adding a proper parent,
		// then you'll need to move this over to ParentType->next and update ParentAccess accordingly.
	}

	while ( possible_slot->Next != nullptr )
	{
		possible_slot = cast(CodeTypename, possible_slot->Next);
	}

	possible_slot->Next = cast(Code, type);
}
#pragma endregion CodeClass

#pragma region CodeParams
inline
void params_append( CodeParams appendee, CodeParams other )
{
	GEN_ASSERT(appendee);
	GEN_ASSERT(other);
	GEN_ASSERT_MSG(appendee != other, "Attempted to append parameter to itself.");
	Code self  = cast(Code, appendee);
	Code entry = cast(Code, other);

	if ( entry->Parent != nullptr )
		entry = code_duplicate( entry );

	entry->Parent = self;

	if ( self->Last == nullptr )
	{
		self->Last = entry;
		self->Next = entry;
		self->NumEntries++;
		return;
	}

	self->Last->Next = entry;
	self->Last       = entry;
	self->NumEntries++;
}
inline
CodeParams params_get(CodeParams self, s32 idx )
{
	GEN_ASSERT(self);
	CodeParams param = self;
	do
	{
		if ( ++ param != nullptr )
			return NullCode;

		param = cast(CodeParams, cast(Code, param)->Next);
	}
	while ( --idx );

	return param;
}
forceinline
bool params_has_entries(CodeParams self)
{
	GEN_ASSERT(self);
	return self->NumEntries > 0;
}
#if GEN_COMPILER_CPP
forceinline
CodeParams& CodeParams::operator ++()
{
	* this = ast->Next;
	return * this;
}
#endif
forceinline
CodeParams begin_CodeParams(CodeParams params)
{
	if ( params != nullptr )
		return params;

	return NullCode;
}
forceinline
CodeParams end_CodeParams(CodeParams params)
{
	// return { (AST_Params*) rcast( AST*, ast)->Last };
	return NullCode;
}
forceinline
CodeParams next_CodeParams(CodeParams params, CodeParams param_iter)
{
	GEN_ASSERT(param_iter);
	return param_iter->Next;
}
#pragma endregion CodeParams

#pragma region CodeDefineParams
forceinline void             define_params_append     (CodeDefineParams appendee, CodeDefineParams other ) { params_append( cast(CodeParams, appendee), cast(CodeParams, other) ); }
forceinline CodeDefineParams define_params_get        (CodeDefineParams self, s32 idx )                    { return (CodeDefineParams) (Code) params_get( cast(CodeParams, self), idx); }
forceinline bool             define_params_has_entries(CodeDefineParams self)                              { return params_has_entries( cast(CodeParams, self)); }

forceinline CodeDefineParams begin_CodeDefineParams(CodeDefineParams params)                              { return (CodeDefineParams) (Code) begin_CodeParams( cast(CodeParams, (Code)params)); }
forceinline CodeDefineParams end_CodeDefineParams  (CodeDefineParams params)                              { return (CodeDefineParams) (Code) end_CodeParams  ( cast(CodeParams, (Code)params)); }
forceinline CodeDefineParams next_CodeDefineParams (CodeDefineParams params, CodeDefineParams entry_iter) { return (CodeDefineParams) (Code) next_CodeParams ( cast(CodeParams, (Code)params), cast(CodeParams, (Code)entry_iter)); }

#if GEN_COMPILER_CPP
forceinline
CodeDefineParams& CodeDefineParams::operator ++()
{
	* this = ast->Next;
	return * this;
}
#endif
#pragma endregion CodeDefineParams

#pragma region CodeSpecifiers
inline
bool specifiers_append(CodeSpecifiers self, Specifier spec )
{
	if ( self == nullptr )
	{
		log_failure("CodeSpecifiers: Attempted to append to a null specifiers AST!");
		return false;
	}
	if ( self->NumEntries == AST_ArrSpecs_Cap )
	{
		log_failure("CodeSpecifiers: Attempted to append over %d specifiers to a specifiers AST!", AST_ArrSpecs_Cap );
		return false;
	}

	self->ArrSpecs[ self->NumEntries ] = spec;
	self->NumEntries++;
	return true;
}
inline
bool specifiers_has(CodeSpecifiers self, Specifier spec)
{
	GEN_ASSERT(self != nullptr);
	for ( s32 idx = 0; idx < self->NumEntries; idx++ ) {
		if ( self->ArrSpecs[ idx ] == spec )
			return true;
	}
	return false;
}
inline
s32 specifiers_index_of(CodeSpecifiers self, Specifier spec)
{
	GEN_ASSERT(self != nullptr);
	for ( s32 idx = 0; idx < self->NumEntries; idx++ ) {
		if ( self->ArrSpecs[ idx ] == spec )
			return idx;
	}
	return -1;
}
inline
s32 specifiers_remove( CodeSpecifiers self, Specifier to_remove )
{
	if ( self == nullptr )
	{
		log_failure("CodeSpecifiers: Attempted to append to a null specifiers AST!");
		return -1;
	}
	if ( self->NumEntries == AST_ArrSpecs_Cap )
	{
		log_failure("CodeSpecifiers: Attempted to append over %d specifiers to a specifiers AST!", AST_ArrSpecs_Cap );
		return -1;
	}

	s32 result = -1;

	s32 curr = 0;
	s32 next = 0;
	for(; next < self->NumEntries; ++ curr, ++ next)
	{
		Specifier spec = self->ArrSpecs[next];
		if (spec == to_remove)
		{
			result = next;

			next ++;
			if (next >= self->NumEntries)
				break;

			spec = self->ArrSpecs[next];
		}

		self->ArrSpecs[ curr ] = spec;
	}

	if (result > -1) {
		self->NumEntries --;
	}
	return result;
}
forceinline
Specifier* begin_CodeSpecifiers(CodeSpecifiers self)
{
	if ( self != nullptr )
		return & self->ArrSpecs[0];

	return nullptr;
}
forceinline
Specifier* end_CodeSpecifiers(CodeSpecifiers self)
{
	return self->ArrSpecs + self->NumEntries;
}
forceinline
Specifier* next_CodeSpecifiers(CodeSpecifiers self, Specifier* spec_iter)
{
	return spec_iter + 1;
}
#pragma endregion CodeSpecifiers

#pragma region CodeStruct
inline
void struct_add_interface(CodeStruct self, CodeTypename type )
{
	CodeTypename possible_slot = self->ParentType;
	if ( possible_slot != nullptr )
	{
		// Were adding an interface to parent type, so we need to make sure the parent type is public.
		self->ParentAccess = AccessSpec_Public;
		// If your planning on adding a proper parent,
		// then you'll need to move this over to ParentType->next and update ParentAccess accordingly.
	}

	while ( possible_slot->Next != nullptr )
	{
		possible_slot = cast(CodeTypename, possible_slot->Next);
	}

	possible_slot->Next = cast(Code, type);
}
#pragma endregion Code

#pragma region Interface
inline
CodeBody def_body( CodeType type )
{
	switch ( type )
	{
		case CT_Class_Body:
		case CT_Enum_Body:
		case CT_Export_Body:
		case CT_Extern_Linkage:
		case CT_Function_Body:
		case CT_Global_Body:
		case CT_Namespace_Body:
		case CT_Struct_Body:
		case CT_Union_Body:
			break;

		default:
			log_failure( "def_body: Invalid type %s", codetype_to_str(type).Ptr );
			return (CodeBody)Code_Invalid;
	}

	Code
	result       = make_code();
	result->Type = type;
	return (CodeBody)result;
}

inline
Str token_fmt_impl( ssize num, ... )
{
	local_persist thread_local
	char buf[GEN_PRINTF_MAXLEN] = { 0 };
	mem_set( buf, 0, GEN_PRINTF_MAXLEN );

	va_list va;
	va_start(va, num );
	ssize result = token_fmt_va(buf, GEN_PRINTF_MAXLEN, num, va);
	va_end(va);

	Str str = { buf, result };
	return str;
}
#pragma endregion Interface
#pragma region generated code inline implementation

inline Code& Code::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline Code::operator bool()
{
	return ast != nullptr;
}

inline CodeBody& CodeBody::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeBody::operator bool()
{
	return ast != nullptr;
}

inline CodeAttributes& CodeAttributes::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeAttributes::operator bool()
{
	return ast != nullptr;
}

inline CodeAttributes::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Attributes* CodeAttributes::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeComment& CodeComment::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeComment::operator bool()
{
	return ast != nullptr;
}

inline CodeComment::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Comment* CodeComment::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeConstructor& CodeConstructor::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeConstructor::operator bool()
{
	return ast != nullptr;
}

inline CodeConstructor::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Constructor* CodeConstructor::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeClass& CodeClass::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeClass::operator bool()
{
	return ast != nullptr;
}

inline CodeDefine& CodeDefine::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeDefine::operator bool()
{
	return ast != nullptr;
}

inline CodeDefine::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Define* CodeDefine::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeDefineParams& CodeDefineParams::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeDefineParams::operator bool()
{
	return ast != nullptr;
}

inline CodeDestructor& CodeDestructor::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeDestructor::operator bool()
{
	return ast != nullptr;
}

inline CodeDestructor::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Destructor* CodeDestructor::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeEnum& CodeEnum::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeEnum::operator bool()
{
	return ast != nullptr;
}

inline CodeEnum::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Enum* CodeEnum::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeExec& CodeExec::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeExec::operator bool()
{
	return ast != nullptr;
}

inline CodeExec::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Exec* CodeExec::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeExtern& CodeExtern::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeExtern::operator bool()
{
	return ast != nullptr;
}

inline CodeExtern::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Extern* CodeExtern::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeFriend& CodeFriend::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeFriend::operator bool()
{
	return ast != nullptr;
}

inline CodeFriend::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Friend* CodeFriend::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeFn& CodeFn::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeFn::operator bool()
{
	return ast != nullptr;
}

inline CodeFn::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Fn* CodeFn::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeInclude& CodeInclude::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeInclude::operator bool()
{
	return ast != nullptr;
}

inline CodeInclude::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Include* CodeInclude::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeModule& CodeModule::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeModule::operator bool()
{
	return ast != nullptr;
}

inline CodeModule::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Module* CodeModule::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeNS& CodeNS::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeNS::operator bool()
{
	return ast != nullptr;
}

inline CodeNS::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_NS* CodeNS::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeOperator& CodeOperator::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeOperator::operator bool()
{
	return ast != nullptr;
}

inline CodeOperator::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Operator* CodeOperator::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeOpCast& CodeOpCast::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeOpCast::operator bool()
{
	return ast != nullptr;
}

inline CodeOpCast::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_OpCast* CodeOpCast::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeParams& CodeParams::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeParams::operator bool()
{
	return ast != nullptr;
}

inline CodePragma& CodePragma::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodePragma::operator bool()
{
	return ast != nullptr;
}

inline CodePragma::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Pragma* CodePragma::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodePreprocessCond& CodePreprocessCond::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodePreprocessCond::operator bool()
{
	return ast != nullptr;
}

inline CodePreprocessCond::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_PreprocessCond* CodePreprocessCond::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeSpecifiers& CodeSpecifiers::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeSpecifiers::operator bool()
{
	return ast != nullptr;
}

inline CodeStruct& CodeStruct::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeStruct::operator bool()
{
	return ast != nullptr;
}

inline CodeTemplate& CodeTemplate::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeTemplate::operator bool()
{
	return ast != nullptr;
}

inline CodeTemplate::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Template* CodeTemplate::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeTypename& CodeTypename::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeTypename::operator bool()
{
	return ast != nullptr;
}

inline CodeTypename::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Typename* CodeTypename::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeTypedef& CodeTypedef::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeTypedef::operator bool()
{
	return ast != nullptr;
}

inline CodeTypedef::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Typedef* CodeTypedef::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeUnion& CodeUnion::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeUnion::operator bool()
{
	return ast != nullptr;
}

inline CodeUnion::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Union* CodeUnion::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeUsing& CodeUsing::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeUsing::operator bool()
{
	return ast != nullptr;
}

inline CodeUsing::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Using* CodeUsing::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

inline CodeVar& CodeVar::operator=(Code other)
{
	if (other.ast != nullptr && other->Parent != nullptr)
	{
		ast         = rcast(decltype(ast), code_duplicate(other).ast);
		ast->Parent = { nullptr };
	}
	ast = rcast(decltype(ast), other.ast);
	return *this;
}

inline CodeVar::operator bool()
{
	return ast != nullptr;
}

inline CodeVar::operator Code()
{
	return *rcast(Code*, this);
}

inline AST_Var* CodeVar::operator->()
{
	if (ast == nullptr)
	{
		log_failure("Attempt to dereference a nullptr!\n");
		return nullptr;
	}
	return ast;
}

#pragma endregion generated code inline implementation

#pragma region generated AST/Code cast implementation
GEN_OPTIMIZE_MAPPINGS_BEGIN

forceinline Code::operator CodeBody() const
{
	return { (AST_Body*)ast };
}

forceinline Code::operator CodeAttributes() const
{
	return { (AST_Attributes*)ast };
}

forceinline Code::operator CodeComment() const
{
	return { (AST_Comment*)ast };
}

forceinline Code::operator CodeConstructor() const
{
	return { (AST_Constructor*)ast };
}

forceinline Code::operator CodeClass() const
{
	return { (AST_Class*)ast };
}

forceinline Code::operator CodeDefine() const
{
	return { (AST_Define*)ast };
}

forceinline Code::operator CodeDefineParams() const
{
	return { (AST_DefineParams*)ast };
}

forceinline Code::operator CodeDestructor() const
{
	return { (AST_Destructor*)ast };
}

forceinline Code::operator CodeEnum() const
{
	return { (AST_Enum*)ast };
}

forceinline Code::operator CodeExec() const
{
	return { (AST_Exec*)ast };
}

forceinline Code::operator CodeExtern() const
{
	return { (AST_Extern*)ast };
}
