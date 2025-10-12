package grime

Nanosecond_To_Microsecond :: 1.0 / (1000.0)
Nanosecond_To_Millisecond :: 1.0 / (1000.0 * 1000.0)
Nanosecond_To_Second      :: 1.0 / (1000.0 * 1000.0 * 1000.0)

Microsecond_To_Nanosecond  :: 1000.0
Microsecond_To_Millisecond :: 1.0 / 1000.0
Microsecond_To_Second      :: 1.0 / (1000.0 * 1000.0)

Millisecond_To_Nanosecond  :: 1000.0 * 1000.0
Millisecond_To_Microsecond :: 1000.0
Millisecond_To_Second      :: 1.0 / 1000.0

Second_To_Nanosecond  :: 1000.0 * 1000.0 * 1000.0
Second_To_Microsecnd  :: 1000.0 * 1000.0
Second_To_Millisecond :: 1000.0

NS_To_MS :: Nanosecond_To_Millisecond
NS_To_US :: Nanosecond_To_Microsecond
NS_To_S  :: Nanosecond_To_Second

US_To_NS :: Microsecond_To_Nanosecond
US_To_MS :: Microsecond_To_Millisecond
US_To_S  :: Microsecond_To_Second

MS_To_NS :: Millisecond_To_Nanosecond
MS_To_US :: Millisecond_To_Microsecond
MS_To_S  :: Millisecond_To_Second

S_To_NS :: Second_To_Nanosecond
S_To_US :: Second_To_Microsecnd
S_To_MS :: Second_To_Millisecond
